(function() {
  var oldOpen = window.XMLHttpRequest.prototype.open;
  var oldSend = window.XMLHttpRequest.prototype.send;
  function newOpen(method, url, async, user, password) {
    this._storedUrl = url;
    return oldOpen.apply(this, arguments);
  }
  function newSend(data) {
    if (this.onload) {
      this._storedOnload = this.onload;
    }
    this.onload = newOnload;
    return oldSend.apply(this, arguments);
  }
  function newOnload() {
    if (
      this._storedUrl.startsWith(
        window.location.protocol + '//' + window.location.host,
      ) ||
      !this._storedUrl.startsWith('http') // For relative paths
    ) {
      var bulletFooterText = this.getResponseHeader('X-bullet-footer-text');
      if (bulletFooterText) {
        setTimeout(() => {
          var oldHtml = document
            .getElementById('bullet-footer')
            .innerHTML.split('<br>');
          var header = oldHtml[0];
          oldHtml = oldHtml.slice(1, oldHtml.length);
          var newHtml = oldHtml.concat(JSON.parse(bulletFooterText));
          newHtml = newHtml.slice(newHtml.length - 10, newHtml.length); // rotate through 10 most recent
          document.getElementById(
            'bullet-footer',
          ).innerHTML = `${header}<br>${newHtml.join('<br>')}`;
        }, 0);
      }
      var bulletConsoleText = this.getResponseHeader('X-bullet-console-text');
      if (bulletConsoleText && typeof console !== 'undefined' && console.log) {
        setTimeout(() => {
          JSON.parse(bulletConsoleText).forEach(message => {
            if (console.groupCollapsed && console.groupEnd) {
              console.groupCollapsed('Uniform Notifier');
              console.log(message);
              console.groupEnd();
            } else {
              console.log(message);
            }
          });
        }, 0);
      }
    }
    if (this._storedOnload) {
      return this._storedOnload.apply(this, arguments);
    }
  }
  window.XMLHttpRequest.prototype.open = newOpen;
  window.XMLHttpRequest.prototype.send = newSend;
})();
