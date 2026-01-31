import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

/**
 * Sortable Controller
 *
 * A reusable Stimulus controller for drag-and-drop table row reordering.
 * Attach to a <tbody> element to enable sorting of its rows.
 *
 * Usage:
 *   <tbody data-controller="sortable"
 *          data-sortable-field-value="Chrono"
 *          data-sortable-handle-value=".drag-handle">
 *     <tr>
 *       <td class="drag-handle"><i class="bi bi-grip-vertical"></i></td>
 *       <td><input type="hidden" name="model[Chrono]" data-sortable-target="orderField"></td>
 *       ...
 *     </tr>
 *   </tbody>
 */
export default class extends Controller {
    static values = {
        field: { type: String, default: "position" },
        handle: { type: String, default: ".drag-handle" },
        increment: { type: Number, default: 10 }
    }

    connect() {
        this.sortable = Sortable.create(this.element, {
            handle: this.handleValue,
            animation: 150,
            ghostClass: "sortable-ghost",
            chosenClass: "sortable-chosen",
            dragClass: "sortable-drag",
            onEnd: this.updateOrder.bind(this)
        })
    }

    disconnect() {
        if (this.sortable) {
            this.sortable.destroy()
        }
    }

    updateOrder() {
        const rows = this.element.querySelectorAll("tr")
        rows.forEach((row, index) => {
            // Look for field by name pattern (e.g., model[Chrono]) or by data-field attribute
            const field = 
              row.querySelector(`[name*="[${this.fieldValue}]"]`) ||
              row.querySelector(`[data-field="${this.fieldValue}"]`)
            if (field) {
                field.value = (index + 1) * this.incrementValue
            }
            row.setAttribute("data-row", index + 1)
        })
    }
}
