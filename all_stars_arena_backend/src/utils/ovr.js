export const calculateOverallRating = (
  winRate = 0,
  goalsScored = 0,
  assists = 0,
  matchesPlayed = 0,
) => {
  if (matchesPlayed < 3) return 70;

  const winRateComponent = (winRate / 100) * 45;
  const matchExperienceComponent = Math.min(matchesPlayed / 50, 1) * 35;
  const goalContributionComponent =
    Math.min((goalsScored + assists) / matchesPlayed, 2) * 19;

  const ovr = Math.round(
    40 +
      winRateComponent +
      matchExperienceComponent +
      goalContributionComponent,
  );
  return Math.min(99, Math.max(40, ovr));
};
