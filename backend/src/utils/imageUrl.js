'use strict';

/**
 * Utility helper to convert relative database file paths to fully qualified URLs.
 * If the image path is already a full HTTP/HTTPS URL, returns it as is.
 * Resolves to default fallback images if the path is missing.
 * Supports dynamic host header detection or static BASE_URL fallback.
 */
function getFullImageUrl(imagePath, req, role) {
  let path = imagePath;
  
  if (!path) {
    if (role === 'admin') {
      path = '/uploads/admin_logo.svg';
    } else {
      path = '/uploads/default_user.png';
    }
  }
  
  // If it's already an absolute external URL, return it
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  
  // Ensure path starts with a single slash
  const cleanPath = path.startsWith('/') ? path : `/${path}`;
  
  // Dynamic host determination
  let host = process.env.BASE_URL_HOST || 'localhost:5000';
  let protocol = 'http';
  
  if (req) {
    host = req.get('host') || host;
    protocol = req.protocol || protocol;
  }
  
  return `${protocol}://${host}${cleanPath}`;
}

module.exports = {
  getFullImageUrl,
};
