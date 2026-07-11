const form = document.getElementById('search-form');
const cityInput = document.getElementById('city-input');
const searchBtn = document.getElementById('search-btn');
const statusEl = document.getElementById('status');
const weatherCard = document.getElementById('weather-card');
const unitBtns = document.querySelectorAll('.unit-btn');

let units = 'metric';

function setStatus(message, type = 'loading') {
  statusEl.textContent = message;
  statusEl.className = `status ${type}`;
  statusEl.classList.remove('hidden');
}

function clearStatus() {
  statusEl.classList.add('hidden');
}

function showWeather(data) {
  document.getElementById('location').textContent = `${data.city}, ${data.country}`;
  document.getElementById('description').textContent = data.description;
  document.getElementById('temp').textContent = data.temp;
  document.getElementById('unit-label').textContent = units === 'imperial' ? '°F' : '°C';
  document.getElementById('feels-like').textContent = `${data.feelsLike}${units === 'imperial' ? '°F' : '°C'}`;
  document.getElementById('humidity').textContent = `${data.humidity}%`;
  document.getElementById('wind').textContent = `${data.wind} ${units === 'imperial' ? 'mph' : 'm/s'}`;
  document.getElementById('weather-icon').src = `https://openweathermap.org/img/wn/${data.icon}@2x.png`;
  document.getElementById('weather-icon').alt = data.description;

  weatherCard.classList.remove('hidden');
  clearStatus();
}

async function fetchWeather(city) {
  setStatus('Fetching weather…');
  weatherCard.classList.add('hidden');
  searchBtn.disabled = true;

  try {
    const response = await fetch(`/api/weather?city=${encodeURIComponent(city)}&units=${units}`);
    const data = await response.json();

    if (!response.ok) {
      setStatus(data.error || 'Something went wrong', 'error');
      return;
    }

    showWeather(data);
  } catch {
    setStatus('Network error — please try again', 'error');
  } finally {
    searchBtn.disabled = false;
  }
}

form.addEventListener('submit', (e) => {
  e.preventDefault();
  const city = cityInput.value.trim();
  if (city) fetchWeather(city);
});

unitBtns.forEach((btn) => {
  btn.addEventListener('click', () => {
    units = btn.dataset.units;
    unitBtns.forEach((b) => b.classList.toggle('active', b === btn));
    const city = cityInput.value.trim();
    if (city) fetchWeather(city);
  });
});

cityInput.value = 'London';
fetchWeather('London');
