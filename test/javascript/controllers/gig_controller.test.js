import GigController from '../../../app/javascript/controllers/gig_controller.js'

jest.mock('@hotwired/stimulus', () => ({Controller: class Controller {}}))

function makeController() {
  const controller = new GigController()
  controller.gigSongIndex = 100
  controller.mediaIndex = 100
  return controller
}

describe('GigController#removeTableRow', () => {
  let controller

  beforeEach(() => {
    controller = makeController()
  })

  test('removes a new row (no id input) directly from the DOM', () => {
    document.body.innerHTML = `
      <table id="t">
        <tbody>
          <tr data-row="1"><td>Song A</td></tr>
          <tr data-row="2"><td>Song B</td></tr>
        </tbody>
      </table>
    `

    controller.removeTableRow('t', 1)

    expect(document.querySelector('tr[data-row="1"]')).toBeNull()
    expect(document.querySelector('tr[data-row="2"]')).not.toBeNull()
  })

  test('hides and marks for destruction rows that have a database id', () => {
    document.body.innerHTML = `
      <table id="t">
        <tbody>
          <tr data-row="1">
            <td><input name="gig[gigsets_attributes][1][id]" value="42"></td>
          </tr>
        </tbody>
      </table>
    `

    controller.removeTableRow('t', 1)

    const row = document.querySelector('tr[data-row="1"]')
    expect(row.style.display).toBe('none')
    const destroy = row.querySelector('input[name="gig[gigsets_attributes][1][_destroy]"]')
    expect(destroy).not.toBeNull()
    expect(destroy.value).toBe('1')
  })

  test('removes the correct row after a drag-and-drop reorder', () => {
    document.body.innerHTML = `
      <table id="t">
        <tbody>
          <tr data-row="1"><td>Song A</td></tr>
          <tr data-row="2"><td>Song B</td></tr>
          <tr data-row="3"><td>Song C</td></tr>
        </tbody>
      </table>
    `

    // Simulate drag: move row 3 (Song C) to first position
    const tbody = document.querySelector('tbody')
    tbody.insertBefore(tbody.children[2], tbody.children[0])
    // DOM order is now: Song C (data-row=3), Song A (data-row=1), Song B (data-row=2)

    // User clicks Remove on Song A — its button still carries rowId=1
    controller.removeTableRow('t', 1)

    expect(document.querySelector('tr[data-row="1"]')).toBeNull()    // Song A removed
    expect(document.querySelector('tr[data-row="2"]')).not.toBeNull() // Song B still present
    expect(document.querySelector('tr[data-row="3"]')).not.toBeNull() // Song C still present
  })

  test('does not remove a different row when rowId matches a reordered position', () => {
    document.body.innerHTML = `
      <table id="t">
        <tbody>
          <tr data-row="1"><td>Song A</td></tr>
          <tr data-row="2"><td>Song B</td></tr>
          <tr data-row="3"><td>Song C</td></tr>
        </tbody>
      </table>
    `

    // Simulate drag: move row 3 to first position
    const tbody = document.querySelector('tbody')
    tbody.insertBefore(tbody.children[2], tbody.children[0])

    // Removing rowId=1 must remove Song A, NOT Song C (which is now at DOM position 1)
    controller.removeTableRow('t', 1)

    expect(document.querySelector('tr[data-row="3"]')).not.toBeNull() // Song C untouched
  })
})
