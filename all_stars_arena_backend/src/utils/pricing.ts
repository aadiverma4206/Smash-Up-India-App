export const calculateCourtPrice = (
  basePrice: number,
  isWeekend: boolean,
  isPeak: boolean,
  peakMultiplier = 1.5,
  weekendMultiplier = 1.75
) => {
  let price = Number(basePrice);
  if (isWeekend) {
    price = price * weekendMultiplier;
  } else if (isPeak) {
    price = price * peakMultiplier;
  }
  return Math.round(price * 100) / 100;
};
