document.addEventListener('DOMContentLoaded', function () {
  const searchInput = document.getElementById('searchInput');
  const searchForm = document.getElementById('searchForm');
  const postList = document.querySelector('ul.post-list');

  // If there's no post list on the page, don't do anything.
  // This ensures the script primarily works on the index page.
  if (!postList) {
    if (searchForm) {
      // Optionally hide the search form if not on the index page
      // searchForm.style.display = 'none';
    }
    return;
  }

  // Prevent form submission if javascript is enabled, as it's a live filter
  if (searchForm) {
    searchForm.addEventListener('submit', function (e) {
      e.preventDefault();
    });
  }

  if (searchInput) {
    searchInput.addEventListener('input', function () {
      const searchTerm = searchInput.value.toLowerCase().trim();
      const listItems = postList.getElementsByTagName('li');

      for (let i = 0; i < listItems.length; i++) {
        const listItem = listItems[i];
        const link = listItem.querySelector('a'); // Post title is in the <a> tag
        let itemText = '';

        if (link) {
          itemText = link.textContent.toLowerCase();
        }

        // You could extend this to search in summaries or other content if available
        // For now, it only searches the link text (post title)

        if (itemText.includes(searchTerm)) {
          listItem.style.display = ''; // Show item
        } else {
          listItem.style.display = 'none'; // Hide item
        }
      }

      // After filtering, update pagination
      if (window.updatePaginationDisplay) {
        const visibleItems = Array.from(listItems).filter(item => item.style.display !== 'none');
        window.updatePaginationDisplay(visibleItems);
      }
    });

    // Handle clearing the search input via the 'x' button
    searchInput.addEventListener('search', function() {
      if (this.value === '') {
        // Reset all items to visible for pagination script to handle
        Array.from(postList.getElementsByTagName('li')).forEach(item => {
          item.style.display = '';
        });
        if (window.updatePaginationDisplay) {
           // Pass all original items to pagination
          window.updatePaginationDisplay(Array.from(postList.getElementsByTagName('li')));
        }
      }
    });
  }
});
