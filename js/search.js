document.addEventListener('DOMContentLoaded', function () {
  const searchInput = document.getElementById('searchInput');
  const searchResultsContainer = document.getElementById('search-results');
  const mainContent = document.getElementById('main-content'); // To hide when results are shown
  const paginationControls = document.getElementById('pagination-controls'); // To hide for site-wide search

  let fuse;
  let searchData = [];

  // Fetch search data
  fetch('/search-data.json')
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json();
    })
    .then(data => {
      searchData = data;
      // Initialize Fuse.js
      const options = {
        keys: ['title', 'content'],
        includeScore: true,
        threshold: 0.4, // Adjust threshold for sensitivity
        ignoreLocation: true, // Search entire strings
      };
      fuse = new Fuse(searchData, options);
    })
    .catch(error => {
      console.error("Failed to load or parse search-data.json:", error);
      if (searchResultsContainer) {
        searchResultsContainer.innerHTML = '<p class="text-danger">Search data could not be loaded.</p>';
      }
    });

  if (searchInput && searchResultsContainer) {
    searchInput.addEventListener('input', function () {
      const searchTerm = searchInput.value.trim();

      if (!fuse) {
        searchResultsContainer.innerHTML = '<p class="text-warning">Search is not ready yet.</p>';
        return;
      }

      if (searchTerm === '') {
        searchResultsContainer.innerHTML = ''; // Clear results
        searchResultsContainer.style.display = 'none';
        if (mainContent) mainContent.style.display = ''; // Show main content
        if (paginationControls) paginationControls.style.display = ''; // Show pagination if present
        // If there was an old post list on the index page, ensure it's visible.
        const postList = document.querySelector('ul.post-list');
        if (postList) {
            postList.style.display = '';
             if (window.updatePaginationDisplay) { // If pagination.js is active
                const allItems = Array.from(postList.getElementsByTagName('li'));
                allItems.forEach(item => item.style.display = ''); // Ensure all items are considered by pagination
                window.updatePaginationDisplay(allItems);
            }
        }
        return;
      }

      const results = fuse.search(searchTerm);
      searchResultsContainer.innerHTML = ''; // Clear previous results
      searchResultsContainer.style.display = 'block';
      if (mainContent) mainContent.style.display = 'none'; // Hide main content area
      if (paginationControls) paginationControls.style.display = 'none'; // Hide pagination

      if (results.length === 0) {
        searchResultsContainer.innerHTML = '<p class="text-muted">No results found.</p>';
      } else {
        const ul = document.createElement('ul');
        ul.className = 'list-group'; // Bootstrap styling
        results.forEach(result => {
          const item = result.item;
          const li = document.createElement('li');
          li.className = 'list-group-item';
          const a = document.createElement('a');
          a.href = item.href;
          a.textContent = item.title;
          li.appendChild(a);
          // Optionally, display a snippet of the content match
          // For example: (This is a simple implementation, could be improved)
          // if (result.matches && result.matches.length > 0) {
          //   const contentMatch = result.matches.find(match => match.key === "content");
          //   if (contentMatch) {
          //     const snippet = document.createElement('p');
          //     snippet.className = 'search-result-snippet text-muted small';
          //     // Display a small part of the matched content (e.g., first 100 chars of the value)
          //     snippet.textContent = contentMatch.value.substring(0, 150) + (contentMatch.value.length > 150 ? '...' : '');
          //     li.appendChild(snippet);
          //   }
          // }
          ul.appendChild(li);
        });
        searchResultsContainer.appendChild(ul);
      }
    });

    // Handle clearing the search input via the 'x' button (if browser supports type="search")
    searchInput.addEventListener('search', function() {
      if (this.value === '') {
        searchResultsContainer.innerHTML = '';
        searchResultsContainer.style.display = 'none';
        if (mainContent) mainContent.style.display = '';
        if (paginationControls) paginationControls.style.display = '';
        const postList = document.querySelector('ul.post-list');
        if (postList) {
            postList.style.display = '';
            if (window.updatePaginationDisplay) {
                const allItems = Array.from(postList.getElementsByTagName('li'));
                allItems.forEach(item => item.style.display = '');
                window.updatePaginationDisplay(allItems);
            }
        }
      }
    });
  } else {
    if (!searchInput) console.log("Search input not found.");
    if (!searchResultsContainer) console.log("Search results container not found.");
  }
});
