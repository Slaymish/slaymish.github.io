document.addEventListener('DOMContentLoaded', function () {
  const shareTwitterButton = document.getElementById('share-twitter');
  const shareFacebookButton = document.getElementById('share-facebook');
  const shareLinkedInButton = document.getElementById('share-linkedin');
  const shareEmailButton = document.getElementById('share-email');

  // Only proceed if at least one share button exists (i.e., we are on a post page)
  if (!shareTwitterButton && !shareFacebookButton && !shareLinkedInButton && !shareEmailButton) {
    return;
  }

  const postUrl = window.location.href;
  // Attempt to get title from <meta name="title"> or document.title as fallback
  let postTitle = document.querySelector('meta[name="title"]') ? document.querySelector('meta[name="title"]').content : document.title;

  // Refine title if it includes site name (common pattern from document.title)
  // Example: "Post Title | My Learning Log" -> "Post Title"
  if (postTitle.includes('|')) {
    postTitle = postTitle.substring(0, postTitle.lastIndexOf('|')).trim();
  }
  // If the h1.post-title exists, prefer its content as it's explicitly the post's title
  const titleElement = document.querySelector('h1.post-title');
  if (titleElement) {
    postTitle = titleElement.textContent.trim();
  }


  if (shareTwitterButton) {
    shareTwitterButton.href = `https://twitter.com/intent/tweet?url=${encodeURIComponent(postUrl)}&text=${encodeURIComponent(postTitle)}`;
  }

  if (shareFacebookButton) {
    shareFacebookButton.href = `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(postUrl)}`;
  }

  if (shareLinkedInButton) {
    shareLinkedInButton.href = `https://www.linkedin.com/shareArticle?mini=true&url=${encodeURIComponent(postUrl)}&title=${encodeURIComponent(postTitle)}`;
  }

  if (shareEmailButton) {
    shareEmailButton.href = `mailto:?subject=${encodeURIComponent(postTitle)}&body=${encodeURIComponent('Check out this post: ' + postUrl)}`;
  }
});
