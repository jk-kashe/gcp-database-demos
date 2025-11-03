import http from 'k6/http';
import { sleep, check } from 'k6';

const managers = ['James', 'Kate', 'Brian', 'Maarten'];

const randomItem = function(items) {
  let max = items.length

  if (max == 1) {
    return items[0]
  }

  let itemIndex = Math.floor(Math.random() * max);
  
  return items[itemIndex]
}

const randomItems = function(items) {
  let max = Math.floor(Math.random() * items.length);

  if (max <= 1) {
    return [randomItem(items)];
  }

  let returnItems = [];
  let returnItemsIndex = {};

  for (let i = 0; i < max; i++) {
    let item = randomItem(items);

    if (returnItemsIndex[item] != null) {
      i--;
    } else {
      returnItems.push(item);
      returnItemsIndex[item] = true;
    }
  }

  return returnItems;
};

const assetSearchBody = function() {
  const types = ['FTS', 'PRECISE'];
  const strategies = ['Europe', 'Asia', 'Technology', 'America'];
  const comparators = ['AND', 'OR'];

  return JSON.stringify({
    type: randomItem(types),
    investment_manager: randomItem(managers),
    investment_strategy: randomItems(strategies),
    investment_strategy_comparator: randomItem(comparators) 
  });
};

const semanticSearchBody = function() {
  const types = ['ANN', 'KNN'];
  const strategies = [
    'Invest in companies which also subscribe to my ideas around climate change, doing good for the planet',
    'Invest in companies at the forefront of disruptive innovation, creating new markets or fundamentally changing existing ones',
    'Invest in companies poised to benefit from major demographic shifts, such as an aging population or the rise of the global middle class',
    'Invest in companies that own and operate critical infrastructure or platforms, effectively acting as toll roads for a specific industry or economy',
    'Invest in companies with exceptionally strong financial health, characterized by low debt, abundant cash reserves, and a consistent history of generating more cash than they consume'
  ]

  return JSON.stringify({
    type: randomItem(types),
    investment_manager: randomItem(managers),
    investment_strategy: randomItem(strategies)
  });
};

const exposureCheckBody = function() {
  const sectors = ['Technology', 'Pharma', 'Semiconductors'];
  const exposures = [10, 20, 30, 40, 50, 60, 70];
  
  return JSON.stringify({
    sector: randomItem(sectors),
    exposure: randomItem(exposures)
  });
};

const baseUrl = __ENV.BASE_URL;
const endpoints = {
  "asset_search": assetSearchBody,
  // "semantic_search": semanticSearchBody,
  "exposure_check": exposureCheckBody,
  "graph": null
};

export const options = {
  scenarios: {
    default: {
      executor: 'constant-vus',
      vus: __ENV.VUS,
      duration: __ENV.DURATION,
      gracefulStop: `${__ENV.VUS * 10}s`
    }
  }
};

export default function() {
  const params = {
    timeout: `${__ENV.VUS * 10}s`,
    headers: {
      Authorization: `Bearer ${__ENV.TOKEN}`
    }
  };

  let endpoint = randomItem(Object.keys(endpoints));
  let res = "";

  if (endpoints[endpoint] == null) {
    res = http.get(`${baseUrl}/${endpoint}`, params);
  } else {
    res = http.post(`${baseUrl}/${endpoint}`, endpoints[endpoint](), params);
  }

  check(res, { "status is 200": (res) => res.status === 200 });
  sleep(1);
}
