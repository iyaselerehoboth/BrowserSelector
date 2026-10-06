const result = document.querySelector('#demo-result');
const remember = document.querySelector('#remember-demo');
let selected = '';
function updateResult() {
  result.textContent = selected
    ? `Demo: ${selected} selected.${remember.checked ? ' This website choice would be remembered.' : ' You would choose again next time.'} No link was opened.`
    : 'Try a destination above. This is a demo; no link opens.';
}
for (const button of document.querySelectorAll('[data-choice]')) {
  button.setAttribute('aria-pressed', 'false');
  button.addEventListener('click', () => {
    selected = button.dataset.choice;
    for (const option of document.querySelectorAll('[data-choice]')) {
      option.setAttribute('aria-pressed', String(option === button));
    }
    updateResult();
  });
}
remember.addEventListener('change', updateResult);
