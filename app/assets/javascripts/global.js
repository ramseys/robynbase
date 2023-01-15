$(window).on("load", function(e) {

  // loop through every table on the current page, and convert it into a datatable
  $("table.main-search-list").each( function(index, tableElement) {

    const table = $(tableElement);

    // get the table's unique identifier, and look for any explicit sorting directives
    // on the table definition
    const tableId = table.data("id");
    const tableSort = table.data("custom-order");

    // look for any previous sorts for this grid (in the current session)
    const orderCookie = Cookies.getJSON("order-" + tableId);

    // no table ordering by default (just display the records in the order they were returned)
    let order = [];

    // if the table requests an initial sort, always use that for the render
    if (tableSort) {
      order = tableSort;

    // otherwise sort base on the last-sorted column (if any)
    } else if (orderCookie) { 
      order = [[orderCookie.column, orderCookie.direction]];
    }

    return $(table).dataTable({

      // change the label of the search control
      language: {
        search: "Filter: "
      },

      // hide the pagination controls if the table only has one page
      // (solution taken from http://stackoverflow.com/a/12393232)
      fnDrawCallback(oSettings) {
        if (oSettings._iDisplayLength > oSettings.fnRecordsDisplay()) {
          return $(oSettings.nTableWrapper).find('.dataTables_paginate').hide();
        }
      },
          
      // put the "results per page" control below the grid (when paging is active)
      sDom: '<"top">rt<"bottom"flp><"clear">',

      // the column to sort by, and the sort direction
      order,

      // render each row as it arrives, rather than pre-rendering the whole table (supposedly faster)
      deferRender: true

    });

  });


  // remember the last sort column/direction for all search lists
  return $(".main-search-list").on("order.dt", function(e, settings) {

    const order = settings.oInstance.DataTable().order();
    const column = order[0][0];
    const direction = order[0][1];

    const tableId = settings.oInstance.data("id");

    Cookies.set("order-" + tableId, { column, direction});

    // console.log(`col ${column}, direction ${direction}`);

  });

});