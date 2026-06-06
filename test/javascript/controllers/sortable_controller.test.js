import SortableController from '../../../app/javascript/controllers/sortable_controller.js'

jest.mock('sortablejs', () => ({__esModule: true, default: {create: jest.fn()}}))
jest.mock('@hotwired/stimulus', () => ({Controller: class Controller {}}))

function makeController(rows) {
  document.body.innerHTML = `<table><tbody>${rows}</tbody></table>`
  const tbody = document.querySelector('tbody')
  const controller = new SortableController()
  controller.element = tbody
  controller.fieldValue = 'Chrono'
  controller.incrementValue = 10
  return {controller, tbody}
}

describe('SortableController#updateOrder', () => {
  test('updates order field values to reflect new DOM positions', () => {
    const {controller, tbody} = makeController(`
      <tr data-row="1"><td><input name="gig[gigsets_attributes][1][Chrono]" value="10"></td></tr>
      <tr data-row="2"><td><input name="gig[gigsets_attributes][2][Chrono]" value="20"></td></tr>
      <tr data-row="3"><td><input name="gig[gigsets_attributes][3][Chrono]" value="30"></td></tr>
    `)

    // Simulate drag: move row 3 to first position
    tbody.insertBefore(tbody.children[2], tbody.children[0])
    controller.updateOrder()

    const inputs = tbody.querySelectorAll('input[name*="[Chrono]"]')
    expect(inputs[0].value).toBe('10') // now at position 1
    expect(inputs[1].value).toBe('20') // now at position 2
    expect(inputs[2].value).toBe('30') // now at position 3
  })

  test('does not modify data-row attributes', () => {
    const {controller, tbody} = makeController(`
      <tr data-row="1"><td><input name="gig[gigsets_attributes][1][Chrono]" value="10"></td></tr>
      <tr data-row="2"><td><input name="gig[gigsets_attributes][2][Chrono]" value="20"></td></tr>
      <tr data-row="3"><td><input name="gig[gigsets_attributes][3][Chrono]" value="30"></td></tr>
    `)

    controller.updateOrder()

    const rows = tbody.querySelectorAll('tr')
    expect(rows[0].getAttribute('data-row')).toBe('1')
    expect(rows[1].getAttribute('data-row')).toBe('2')
    expect(rows[2].getAttribute('data-row')).toBe('3')
  })

  test('preserves data-row after reorder so remove buttons still target the right rows', () => {
    const {controller, tbody} = makeController(`
      <tr data-row="1"><td><input name="gig[gigsets_attributes][1][Chrono]" value="10"></td></tr>
      <tr data-row="2"><td><input name="gig[gigsets_attributes][2][Chrono]" value="20"></td></tr>
      <tr data-row="3"><td><input name="gig[gigsets_attributes][3][Chrono]" value="30"></td></tr>
    `)

    // Simulate drag: move row 3 to first position
    tbody.insertBefore(tbody.children[2], tbody.children[0])
    controller.updateOrder()

    // data-row must travel with the row, not be reassigned by position
    expect(tbody.children[0].getAttribute('data-row')).toBe('3')
    expect(tbody.children[1].getAttribute('data-row')).toBe('1')
    expect(tbody.children[2].getAttribute('data-row')).toBe('2')
  })
})
