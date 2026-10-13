import fs from 'fs';
import path from 'path';

// 1. Manager Game Details View
const mGameViewPath = path.resolve('../lib/modules/manager/views/manager_game_details_view.dart');
let mGameViewContent = fs.readFileSync(mGameViewPath, 'utf8');

if (!mGameViewContent.includes("import '../../../data/models/video_model.dart';")) {
  mGameViewContent = mGameViewContent.replace(
    "import '../../../data/models/game_model.dart';",
    "import '../../../data/models/game_model.dart';\nimport '../../../data/models/video_model.dart';"
  );
}

const newGameCctvSection = fs.readFileSync('scratch/cctv_section_manager_game.dart', 'utf8');
const gameCctvIdx = mGameViewContent.indexOf('Widget _buildCctvVideoSection(BuildContext context, GameModel game) {');
if (gameCctvIdx !== -1) {
  const endSectionIdx = mGameViewContent.indexOf('  Widget _buildRosterPaymentSection', gameCctvIdx);
  if (endSectionIdx !== -1) {
    const commentIdx = mGameViewContent.lastIndexOf('  ///', gameCctvIdx);
    const replaceStart = (commentIdx !== -1 && commentIdx > gameCctvIdx - 50) ? commentIdx : gameCctvIdx;
    mGameViewContent = mGameViewContent.slice(0, replaceStart) + newGameCctvSection + '\n\n' + mGameViewContent.slice(endSectionIdx);
    fs.writeFileSync(mGameViewPath, mGameViewContent, 'utf8');
    console.log('✓ Successfully updated manager_game_details_view.dart');
  } else {
    console.log('End of _buildCctvVideoSection not found');
  }
}

// 2. Game Details View
const gViewPath = path.resolve('../lib/modules/games/views/game_details_view.dart');
let gViewContent = fs.readFileSync(gViewPath, 'utf8');

const newPlayerVidSec = fs.readFileSync('scratch/video_section_game_details.dart', 'utf8');
const vidSecIdx = gViewContent.indexOf('Widget _buildVideoSection(');
if (vidSecIdx !== -1) {
  gViewContent = gViewContent.slice(0, vidSecIdx) + newPlayerVidSec + '\n}\n';
  fs.writeFileSync(gViewPath, gViewContent, 'utf8');
  console.log('✓ Successfully updated game_details_view.dart');
}
