import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    url: String,
    currentPage: Number,
    hasNextPage: Boolean,
    currentSort: String,
    currentDirection: String,
    searchType: String,
    searchValue: String,
    queryType: String,
    queryId: String,
    queryAttribute: String,
    advancedQueryParams: Object
  }
  
  static targets = ["tbody"]

  connect() {
    console.log('Infinite scroll controller connected')
    console.log('URL:', this.urlValue)
    console.log('Current page:', this.currentPageValue)
    console.log('Has next page:', this.hasNextPageValue)
    this.loading = false
    this.bindScrollEvent()

    // Check if we need to fill the screen after initial load
    if (this.tbodyTarget.children.length > 0) {
      this.ensureScreenFilled()
    }
  }

  disconnect() {
    this.unbindScrollEvent()
  }

  bindScrollEvent() {
    this.scrollHandler = this.handleScroll.bind(this)
    window.addEventListener('scroll', this.scrollHandler)
  }

  unbindScrollEvent() {
    if (this.scrollHandler) {
      window.removeEventListener('scroll', this.scrollHandler)
    }
  }

  handleScroll() {
    if (this.loading || !this.hasNextPageValue) {
      console.log('Scroll ignored - loading:', this.loading, 'hasNextPage:', this.hasNextPageValue)
      return
    }

    const scrollTop = window.pageYOffset || document.documentElement.scrollTop
    const windowHeight = window.innerHeight
    const documentHeight = document.documentElement.scrollHeight
    const distanceFromBottom = documentHeight - (scrollTop + windowHeight)
    
    // console.log('Scroll position - distance from bottom:', distanceFromBottom)
    
    // Trigger when user is within 200px of bottom
    if (scrollTop + windowHeight >= documentHeight - 200) {
      console.log('Loading next page...')
      this.loadNextPage()
    }
  }

  async loadNextPage() {
    if (this.loading || !this.hasNextPageValue) return

    this.loading = true
    this.showLoadingIndicator()

    try {
      const nextPage = this.currentPageValue + 1
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set('page', nextPage)
      
      // Add search parameters
      if (this.searchTypeValue) {
        url.searchParams.set('search_type', this.searchTypeValue || '')
      }
      if (this.searchValueValue) {
        url.searchParams.set('search_value', this.searchValueValue === 'null' ? '' : this.searchValueValue)
      }
      
      // Add current sort parameters
      if (this.currentSortValue) {
        url.searchParams.set('sort', this.currentSortValue)
      }
      if (this.currentDirectionValue) {
        url.searchParams.set('direction', this.currentDirectionValue)
      }
      
      // Add query type parameters
      if (this.queryTypeValue) {
        url.searchParams.set('query_type', this.queryTypeValue)
      }
      if (this.queryIdValue) {
        url.searchParams.set('query_id', this.queryIdValue)
      }
      if (this.queryAttributeValue) {
        url.searchParams.set('query_attribute', this.queryAttributeValue)
      }
      
      // Add advanced query parameters
      if (this.advancedQueryParamsValue) {
        Object.entries(this.advancedQueryParamsValue).forEach(([key, value]) => {
          if (value !== null && value !== undefined && value !== '') {
            // Handle arrays - Rails expects array params as key[]
            if (Array.isArray(value)) {
              value.forEach(item => {
                url.searchParams.append(`${key}[]`, item)
              })
            } else {
              url.searchParams.set(key, value)
            }
          }
        })
      }

      console.log('Fetching URL:', url.toString())

      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      console.log('Response status:', response.status)
      console.log('Response headers:', response.headers.get('content-type'))

      if (!response.ok) throw new Error(`Network response was not ok: ${response.status}`)

      const data = await response.json()
      console.log('Response data:', data)
      
      // Append new rows to table
      this.tbodyTarget.insertAdjacentHTML('beforeend', data.html)
      
      // Update pagination, sort, search, and query state
      this.currentPageValue = data.current_page
      this.hasNextPageValue = data.has_next_page
      if (data.current_sort !== undefined) this.currentSortValue = data.current_sort
      if (data.current_direction !== undefined) this.currentDirectionValue = data.current_direction
      if (data.search_type !== undefined) this.searchTypeValue = data.search_type
      if (data.search_value !== undefined) this.searchValueValue = data.search_value
      if (data.query_type !== undefined) this.queryTypeValue = data.query_type
      if (data.query_id !== undefined) this.queryIdValue = data.query_id
      if (data.query_attribute !== undefined) this.queryAttributeValue = data.query_attribute

      console.log('Updated state - Page:', this.currentPageValue, 'HasNext:', this.hasNextPageValue, 'Sort:', this.currentSortValue, 'Direction:', this.currentDirectionValue, 'QueryType:', this.queryTypeValue)

      // Check if we need to load more data to fill the screen
      this.ensureScreenFilled()

    } catch (error) {
      console.error('Error loading next page:', error)
    } finally {
      this.loading = false
      this.hideLoadingIndicator()
    }
  }

  showLoadingIndicator() {
    // Add loading indicator if it doesn't exist
    if (!this.element.querySelector('.infinite-scroll-loading')) {
      const indicator = document.createElement('div')
      indicator.className = 'infinite-scroll-loading text-center p-3'
      indicator.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Loading more songs...'
      this.element.appendChild(indicator)
    }
  }

  hideLoadingIndicator() {
    const indicator = this.element.querySelector('.infinite-scroll-loading')
    if (indicator) {
      indicator.remove()
    }
  }

  ensureScreenFilled() {
    if (this.loading || !this.hasNextPageValue) {
      return
    }

    const availableHeight = this.calculateAvailableHeight()
    const estimatedRowHeight = this.getEstimatedRowHeight()
    const neededRows = Math.ceil(availableHeight / estimatedRowHeight) + 3 // +3 buffer
    const currentRows = this.tbodyTarget.children.length

    console.log(`Screen filling check: need ${neededRows} rows, have ${currentRows}`)

    if (currentRows < neededRows) {
      console.log('Loading more data to fill screen...')
      this.loadNextPage()
    }
  }

  calculateAvailableHeight() {
    const viewportHeight = window.innerHeight
    const tableElement = this.element.closest('table')
    const tableRect = tableElement.getBoundingClientRect()

    // Available height = viewport minus table's distance from top minus bottom buffer
    return Math.max(viewportHeight - tableRect.top - 50, 200)
  }

  getEstimatedRowHeight() {
    const firstRow = this.tbodyTarget.querySelector('tr')
    return firstRow ? firstRow.offsetHeight : 60 // fallback to 60px
  }
}