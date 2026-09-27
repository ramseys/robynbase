import InfiniteScrollController from '../../../app/javascript/controllers/infinite_scroll_controller.js'

jest.mock('@hotwired/stimulus', () => ({Controller: class Controller {}}))

const PAGE_SIZE = 40
const ROW_HEIGHT = 40

// jsdom has no layout engine: every element reports 0 for offsetHeight and for
// scroll geometry. The controller divides by the row height to decide how many
// rows fill a screen, so leaving it at 0 gives Infinity and the harness loads
// forever. Stubbing these is what stands in for layout.
function stubLayout({scrollTop, innerHeight, documentHeight}) {
  Object.defineProperty(HTMLTableRowElement.prototype, 'offsetHeight', {value: ROW_HEIGHT, configurable: true})
  Object.defineProperty(window, 'pageYOffset', {value: scrollTop, configurable: true})
  Object.defineProperty(document.documentElement, 'scrollHeight', {value: documentHeight, configurable: true})
  window.innerHeight = innerHeight
}

function rows(count, prefix) {
  return Array.from({length: count}, (_, i) => `<tr data-row="${prefix}-${i}"><td>Song ${prefix}-${i}</td></tr>`).join('')
}

// Mirrors the index pages: the table sits inside .search-results, which is a
// plain padding wrapper and never scrolls - the document does. A controller
// that listens anywhere but the window hears nothing here, which is exactly
// the regression these tests exist to catch.
function mount({initialRows = PAGE_SIZE, hasNextPage = true, values = {}} = {}) {
  document.body.innerHTML = `
    <div class="search-results">
      <table>
        <tbody>${rows(initialRows, 'a')}</tbody>
      </table>
    </div>
  `

  const controller = new InfiniteScrollController()
  controller.element = document.querySelector('table')
  controller.tbodyTarget = document.querySelector('tbody')
  controller.urlValue = '/songs/infinite_scroll'
  controller.currentPageValue = 1
  controller.hasNextPageValue = hasNextPage
  controller.currentSortValue = 'name'
  controller.currentDirectionValue = 'asc'
  controller.searchTypeValue = 'all'
  controller.searchValueValue = 'a'
  controller.queryTypeValue = ''
  controller.queryIdValue = ''
  controller.queryAttributeValue = ''
  controller.advancedQueryParamsValue = {}
  Object.assign(controller, values)

  return controller
}

// One page of rows, as the infinite_scroll endpoint returns them
function respondWith({html, hasNextPage = true, page = 2}) {
  return {
    ok: true,
    json: async () => ({
      html: html,
      has_next_page: hasNextPage,
      current_page: page,
      current_sort: 'name',
      current_direction: 'asc',
      search_type: 'all',
      search_value: 'a'
    })
  }
}

// The controller awaits a fetch and then may immediately queue another load,
// so a single microtask flush isn't always enough to settle it
async function settle() {
  for (let i = 0; i < 10; i++) {
    await Promise.resolve()
    await new Promise(resolve => setTimeout(resolve, 0))
  }
}

function scrollToBottom() {
  stubLayout({scrollTop: 4200, innerHeight: 800, documentHeight: 5000})
  window.dispatchEvent(new Event('scroll'))
}

describe('InfiniteScrollController', () => {
  let controller
  let consoleLog

  beforeEach(() => {
    // connect() logs its state on every mount - useful in a browser, just noise here
    consoleLog = jest.spyOn(console, 'log').mockImplementation(() => {})
    // far from the bottom, and a screen already full, so connect() doesn't load
    stubLayout({scrollTop: 0, innerHeight: 800, documentHeight: 5000})
  })

  afterEach(() => {
    if (controller) controller.disconnect()
    controller = null
    delete global.fetch
    consoleLog.mockRestore()
  })

  test('scrolling to the bottom of the window loads and appends the next page', async () => {
    global.fetch = jest.fn(async () => respondWith({html: rows(PAGE_SIZE, 'b')}))

    controller = mount()
    controller.connect()
    expect(controller.tbodyTarget.children.length).toBe(PAGE_SIZE)

    scrollToBottom()
    await settle()

    expect(global.fetch).toHaveBeenCalled()
    expect(controller.tbodyTarget.children.length).toBe(PAGE_SIZE * 2)
    // the appended rows are the ones the endpoint returned, in order
    expect(controller.tbodyTarget.children[PAGE_SIZE].dataset.row).toBe('b-0')
  })

  test('requests the next page number with the search and sort params', async () => {
    global.fetch = jest.fn(async () => respondWith({html: rows(PAGE_SIZE, 'b')}))

    controller = mount()
    controller.connect()
    scrollToBottom()
    await settle()

    const requested = new URL(global.fetch.mock.calls[0][0])
    expect(requested.pathname).toBe('/songs/infinite_scroll')
    expect(requested.searchParams.get('page')).toBe('2')
    expect(requested.searchParams.get('search_type')).toBe('all')
    expect(requested.searchParams.get('search_value')).toBe('a')
    expect(requested.searchParams.get('sort')).toBe('name')
    expect(requested.searchParams.get('direction')).toBe('asc')
  })

  test('a scroll that is not near the bottom loads nothing', async () => {
    global.fetch = jest.fn(async () => respondWith({html: rows(PAGE_SIZE, 'b')}))

    controller = mount()
    controller.connect()

    stubLayout({scrollTop: 100, innerHeight: 800, documentHeight: 5000})
    window.dispatchEvent(new Event('scroll'))
    await settle()

    expect(global.fetch).not.toHaveBeenCalled()
    expect(controller.tbodyTarget.children.length).toBe(PAGE_SIZE)
  })

  test('stops loading once the response reports no further pages', async () => {
    global.fetch = jest.fn(async () => respondWith({html: rows(PAGE_SIZE, 'b'), hasNextPage: false}))

    controller = mount()
    controller.connect()

    scrollToBottom()
    await settle()
    expect(global.fetch).toHaveBeenCalledTimes(1)

    // hitting the bottom again must not fire another request
    scrollToBottom()
    await settle()
    expect(global.fetch).toHaveBeenCalledTimes(1)
    expect(controller.tbodyTarget.children.length).toBe(PAGE_SIZE * 2)
  })

  test('does not request anything when it starts on the last page', async () => {
    global.fetch = jest.fn(async () => respondWith({html: rows(PAGE_SIZE, 'b')}))

    controller = mount({hasNextPage: false})
    controller.connect()
    scrollToBottom()
    await settle()

    expect(global.fetch).not.toHaveBeenCalled()
  })

  test('loads more when the first page leaves the screen unfilled', async () => {
    global.fetch = jest.fn(async () => respondWith({html: rows(PAGE_SIZE, 'b'), hasNextPage: false}))

    // three rows against an 800px viewport is nowhere near a full screen
    controller = mount({initialRows: 3})
    controller.connect()
    await settle()

    expect(global.fetch).toHaveBeenCalled()
    expect(controller.tbodyTarget.children.length).toBe(3 + PAGE_SIZE)
  })

  test('treats unmeasurable rows as a default height instead of paging forever', async () => {
    // Rows measure 0 when hidden or not yet laid out. That used to divide into
    // an infinite needed-row count, so ensureScreenFilled kept requesting until
    // the result set ran out; the fallback height has to stop that.
    Object.defineProperty(HTMLTableRowElement.prototype, 'offsetHeight', {value: 0, configurable: true})

    let page = 1
    global.fetch = jest.fn(async () => {
      page += 1
      return respondWith({html: rows(PAGE_SIZE, `p${page}`), page: page})
    })

    controller = mount()
    controller.connect()
    await settle()

    // 800px of viewport at the 60px fallback needs ~16 rows; the 40 already
    // present cover it, so nothing should be requested at all
    expect(global.fetch).not.toHaveBeenCalled()
    expect(controller.tbodyTarget.children.length).toBe(PAGE_SIZE)
  })

  test('a failed request leaves the existing rows alone and recovers', async () => {
    global.fetch = jest.fn(async () => ({ok: false, status: 500}))

    controller = mount()
    const consoleError = jest.spyOn(console, 'error').mockImplementation(() => {})

    controller.connect()
    scrollToBottom()
    await settle()

    expect(controller.tbodyTarget.children.length).toBe(PAGE_SIZE)
    expect(document.querySelector('.infinite-scroll-loading')).toBeNull()

    // the controller has to be usable again after a failure, not wedged on this.loading
    global.fetch = jest.fn(async () => respondWith({html: rows(PAGE_SIZE, 'b'), hasNextPage: false}))
    scrollToBottom()
    await settle()

    expect(controller.tbodyTarget.children.length).toBe(PAGE_SIZE * 2)
    consoleError.mockRestore()
  })

  test('stops listening once disconnected', async () => {
    global.fetch = jest.fn(async () => respondWith({html: rows(PAGE_SIZE, 'b')}))

    controller = mount()
    controller.connect()
    controller.disconnect()

    scrollToBottom()
    await settle()

    expect(global.fetch).not.toHaveBeenCalled()
  })
})
