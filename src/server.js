const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const API_KEY = process.env.OPENWEATHER_API_KEY;

app.use(express.static(path.join(__dirname, 'public')));

app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/api/weather', async (req, res) => {
  const city = (req.query.city || '').trim();
  const units = req.query.units === 'imperial' ? 'imperial' : 'metric';

  if (!city) {
    return res.status(400).json({ error: 'City name is required' });
  }

  if (!API_KEY) {
    return res.status(503).json({ error: 'Weather service is not configured' });
  }

  const url = new URL('https://api.openweathermap.org/data/2.5/weather');
  url.searchParams.set('q', city);
  url.searchParams.set('appid', API_KEY);
  url.searchParams.set('units', units);

  try {
    const response = await fetch(url);
    const data = await response.json();

    if (!response.ok) {
      const message = data.message || 'Failed to fetch weather data';
      return res.status(response.status).json({ error: message });
    }

    res.json({
      city: data.name,
      country: data.sys?.country,
      temp: Math.round(data.main.temp),
      feelsLike: Math.round(data.main.feels_like),
      humidity: data.main.humidity,
      wind: Math.round(data.wind.speed),
      description: data.weather[0]?.description,
      icon: data.weather[0]?.icon,
      units,
    });
  } catch {
    res.status(502).json({ error: 'Unable to reach weather service' });
  }
});

app.get('*', (_req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Vibe Weather running on http://0.0.0.0:${PORT}`);
});
