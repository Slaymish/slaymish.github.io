document.addEventListener('DOMContentLoaded', function () {
  const postList = document.querySelector('ul.post-list');
  const paginationControlsContainer = document.getElementById('pagination-controls');

  if (!postList || !paginationControlsContainer) {
    // Only run on pages with a post list and pagination container (i.e., index page)
    if (paginationControlsContainer) paginationControlsContainer.style.display = 'none';
    return;
  }

  const listItems = Array.from(postList.getElementsByTagName('li'));
  const itemsPerPage = 5; // Or 10, or make it configurable
  let currentPage = 1;
  let currentFilteredItems = listItems; // Initially, all items are considered

  function displayPage(page, items) {
    currentPage = page;
    // First, hide all items in the full list (respecting search.js's display:none)
    listItems.forEach(item => {
      if (item.style.display !== 'none') { // if not hidden by search
        item.style.display = 'none'; // hide for pagination
      }
    });

    // Then, show only the items for the current page from the filtered list
    const startIndex = (page - 1) * itemsPerPage;
    const endIndex = startIndex + itemsPerPage;
    items.slice(startIndex, endIndex).forEach(item => {
      item.style.display = ''; // Show item (as block or list-item)
    });

    renderControls(items);
  }

  function renderControls(items) {
    paginationControlsContainer.innerHTML = ''; // Clear existing controls
    const totalPages = Math.ceil(items.length / itemsPerPage);

    if (totalPages <= 1) {
      paginationControlsContainer.style.display = 'none';
      return;
    }
    paginationControlsContainer.style.display = 'flex';


    // Previous Button
    const prevButton = document.createElement('button');
    prevButton.textContent = 'Previous';
    prevButton.classList.add('btn', 'btn-outline-primary', 'me-2');
    prevButton.disabled = currentPage === 1;
    prevButton.addEventListener('click', () => {
      if (currentPage > 1) {
        displayPage(currentPage - 1, items);
      }
    });
    paginationControlsContainer.appendChild(prevButton);

    // Page Numbers (optional, can be simple or more complex)
    for (let i = 1; i <= totalPages; i++) {
      const pageButton = document.createElement('button');
      pageButton.textContent = i;
      pageButton.classList.add('btn', 'btn-outline-primary', 'me-2');
      if (i === currentPage) {
        pageButton.classList.add('active');
        pageButton.disabled = true;
      }
      pageButton.addEventListener('click', () => displayPage(i, items));
      paginationControlsContainer.appendChild(pageButton);
    }

    // Next Button
    const nextButton = document.createElement('button');
    nextButton.textContent = 'Next';
    nextButton.classList.add('btn', 'btn-outline-primary');
    nextButton.disabled = currentPage === totalPages;
    nextButton.addEventListener('click', () => {
      if (currentPage < totalPages) {
        displayPage(currentPage + 1, items);
      }
    });
    paginationControlsContainer.appendChild(nextButton);
  }

  // Function to be called by search.js when search results change
  function updatePaginationForSearch(filteredItems) {
    currentFilteredItems = filteredItems;
    displayPage(1, currentFilteredItems); // Reset to page 1 of filtered items
  }

  // Make updatePaginationForSearch globally accessible for search.js
  // Or use custom events: document.dispatchEvent(new CustomEvent('searchFiltered', { detail: { filteredItems } }));
  // And here: document.addEventListener('searchFiltered', (e) => updatePaginationForSearch(e.detail.filteredItems));
  window.updatePaginationDisplay = updatePaginationForSearch;


  // Initial display
  displayPage(1, currentFilteredItems);

  // This is a simple way to listen for search changes.
  // A more robust solution would be for search.js to explicitly call updatePaginationDisplay.
  const searchInput = document.getElementById('searchInput');
  if (searchInput) {
    searchInput.addEventListener('input', () => {
      // When search input changes, filter visible items from the DOM
      // This assumes search.js has already hidden/shown items.
      const visibleItems = listItems.filter(item => item.style.display !== 'none');
      updatePaginationDisplay(visibleItems);
    });
     // Also handle clearing the search
    searchInput.addEventListener('search', function() { // 'search' event fires when 'x' is clicked
        if (this.value === '') {
            updatePaginationDisplay(listItems); // Reset to all items
        }
    });
  }
});
