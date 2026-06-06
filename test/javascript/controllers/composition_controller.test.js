import CompositionController from '../../../app/javascript/controllers/composition_controller.js'

jest.mock('@hotwired/stimulus', () => ({Controller: class Controller {}}))

function makeController() {
  const controller = new CompositionController()
  controller.compositionSongIndex = 100
  return controller
}

describe('CompositionController#removeCompositionTableRow', () => {
  let controller

  beforeEach(() => {
    controller = makeController()
  })

  test('removes a new row (no id input) directly from the DOM', () => {
    document.body.innerHTML = `
      <table id="t">
        <tbody>
          <tr data-row="1"><td>Track 1</td></tr>
          <tr data-row="2"><td>Track 2</td></tr>
        </tbody>
      </table>
    `

    controller.removeCompositionTableRow('t', 1)

    expect(document.querySelector('tr[data-row="1"]')).toBeNull()
    expect(document.querySelector('tr[data-row="2"]')).not.toBeNull()
  })

  test('hides and marks for destruction rows that have a database id', () => {
    document.body.innerHTML = `
      <table id="t">
        <tbody>
          <tr data-row="1">
            <td><input name="composition[tracks_attributes][1][id]" value="99"></td>
          </tr>
        </tbody>
      </table>
    `

    controller.removeCompositionTableRow('t', 1)

    const row = document.querySelector('tr[data-row="1"]')
    expect(row.style.display).toBe('none')
    const destroy = row.querySelector('input[name="composition[tracks_attributes][1][_destroy]"]')
    expect(destroy).not.toBeNull()
    expect(destroy.value).toBe('1')
  })

  test('removes the correct track after a drag-and-drop reorder', () => {
    document.body.innerHTML = `
      <table id="t">
        <tbody>
          <tr data-row="1"><td>Track A</td></tr>
          <tr data-row="2"><td>Track B</td></tr>
          <tr data-row="3"><td>Track C</td></tr>
        </tbody>
      </table>
    `

    // Simulate drag: move row 3 (Track C) to first position
    const tbody = document.querySelector('tbody')
    tbody.insertBefore(tbody.children[2], tbody.children[0])
    // DOM order is now: Track C (data-row=3), Track A (data-row=1), Track B (data-row=2)

    // User clicks Remove on Track A — its button still carries rowId=1
    controller.removeCompositionTableRow('t', 1)

    expect(document.querySelector('tr[data-row="1"]')).toBeNull()    // Track A removed
    expect(document.querySelector('tr[data-row="2"]')).not.toBeNull() // Track B still present
    expect(document.querySelector('tr[data-row="3"]')).not.toBeNull() // Track C still present
  })

  test('does not remove a different row when rowId matches a reordered position', () => {
    document.body.innerHTML = `
      <table id="t">
        <tbody>
          <tr data-row="1"><td>Track A</td></tr>
          <tr data-row="2"><td>Track B</td></tr>
          <tr data-row="3"><td>Track C</td></tr>
        </tbody>
      </table>
    `

    // Simulate drag: move row 3 to first position
    const tbody = document.querySelector('tbody')
    tbody.insertBefore(tbody.children[2], tbody.children[0])

    // Removing rowId=1 must remove Track A, NOT Track C (which is now at DOM position 1)
    controller.removeCompositionTableRow('t', 1)

    expect(document.querySelector('tr[data-row="3"]')).not.toBeNull() // Track C untouched
  })
})
