import jQuery from 'jquery';
import Cookies from 'js-cookie';
import DataTable from 'datatables.net-dt';

// $(window).on("load", function(e) {
$(document).ready(function(e) {

  // loop through every table on the current page, and convert it into a datatable
  $("table.main-search-list").each( function(index, tableElement) {

    const table = $(tableElement);

    // get the table's unique identifier, and look for any explicit sorting directives
    // on the table definition
    const tableId = table.data("id");
    const tableSort = table.data("custom-order");
    const tableName = table.data("table-name");

    // look for any previous sorts for this grid (in the current session)
    const orderCookieRaw = Cookies.get("order-" + tableId);
    const orderCookie = orderCookieRaw ? JSON.parse(orderCookieRaw) : undefined;

    // no table ordering by default (just display the records in the order they were returned)
    let order = [];

    // if the table requests an initial sort, always use that for the render
    if (tableSort) {
      order = tableSort;

    // otherwise sort base on the last-sorted column (if any)
    } else if (orderCookie) { 
      order = [[orderCookie.column, orderCookie.direction]];
    }

    new DataTable(table, {

      // hide the pagination controls if the table only has one page
      // (solution taken from http://stackoverflow.com/a/12393232)
          
      // put the "results per page" control below the grid (when paging is active)

      // the column to sort by, and the sort direction
      order,

      // render each row as it arrives, rather than pre-rendering the whole table (supposedly faster)
      deferRender: true,

      layout: {
        topStart: {
          div: {
            html: `<h3 class='section-header'>${tableName}</h3>`,
          }
        },
        topEnd: "search",
      },

    }).on("order.dt", function(e, settings) {
    
      console.log("ORDER");
      
      const order = settings.oInstance.DataTable().order();
      const column = order[0][0];
      const direction = order[0][1];
    
      const tableId = settings.oInstance.data("id");
    
      console.log(`col ${column}, direction ${direction}`);
      Cookies.set("order-" + tableId, JSON.stringify({ column, direction}));
    
    
    });
    
  });

});