(function () {
  document.addEventListener('DOMContentLoaded', function () {
    var tabs = document.querySelectorAll('[data-role-tab]');
    if (!tabs.length) return;
    var hidden = document.querySelector('input[name="account_type"]');
    tabs.forEach(function (btn) {
      btn.addEventListener('click', function () {
        tabs.forEach(function (b) { b.classList.remove('is-active'); });
        btn.classList.add('is-active');
        if (hidden) hidden.value = btn.dataset.roleTab;
      });
    });
  });
})();
