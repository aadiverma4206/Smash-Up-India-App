/**
 * Calculate Player Overall Rating (OVR: 40 - 99)
 * Based purely on match statistics: Win Rate, Goals/Assists performance, and Matches Played.
 */
export const calculateOverallRating = (
  winRate = 0,
  goalsScored = 0,
  assists = 0,
  matchesPlayed = 0,
) => {
  if (matchesPlayed < 3) return 70; // Baseline OVR for new player recruits

  const winRateComponent = (winRate / 100) * 45; // Max 45 pts
  const matchExperienceComponent = Math.min(matchesPlayed / 50, 1) * 35; // Max 35 pts
  const goalContributionComponent =
    Math.min((goalsScored + assists) / matchesPlayed, 2) * 19; // Max 19 pts

  const ovr = Math.round(
    40 +
      winRateComponent +
      matchExperienceComponent +
      goalContributionComponent,
  );
  return Math.min(99, Math.max(40, ovr));
};
