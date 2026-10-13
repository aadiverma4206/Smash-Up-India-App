import fs from 'fs';
import path from 'path';

// 1. Manager History Detail View
const mHistViewPath = path.resolve('../lib/modules/manager/views/manager_history_detail_view.dart');
let mHistViewContent = fs.readFileSync(mHistViewPath, 'utf8');

if (!mHistViewContent.includes("import '../../../data/models/video_model.dart';")) {
  mHistViewContent = mHistViewContent.replace(
    "import '../../../data/models/game_model.dart';",
    "import '../../../data/models/game_model.dart';\nimport '../../../data/models/video_model.dart';"
  );
}

if (!mHistViewContent.includes('controller.fetchMatchRecording(game.id)')) {
  mHistViewContent = mHistViewContent.replace(
    "        final game = controller.selectedGame.value;\n        if (game == null) {\n          return const AppLoader(message: 'Loading match history details...');\n        }",
    `        final game = controller.selectedGame.value;
        if (game == null) {
          return const AppLoader(message: 'Loading match history details...');
        }

        // Auto-fetch recordings and cameras dynamically for this match
        if (controller.matchVideos.isEmpty && !controller.isLoadingVideos.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.fetchMatchRecording(game.id);
          });
        }`
  );
}

const newHistCctvSection = fs.readFileSync('scratch/cctv_section_manager_history.dart', 'utf8');
const histCctvIdx = mHistViewContent.indexOf('Widget _buildCctvSection(BuildContext context, GameModel game) {');
if (histCctvIdx !== -1) {
  // Find preceding comment if any
  const commentIdx = mHistViewContent.lastIndexOf('  ///', histCctvIdx);
  const replaceStart = (commentIdx !== -1 && commentIdx > histCctvIdx - 50) ? commentIdx : histCctvIdx;
  mHistViewContent = mHistViewContent.slice(0, replaceStart) + newHistCctvSection;
  fs.writeFileSync(mHistViewPath, mHistViewContent, 'utf8');
  console.log('✓ Updated manager_history_detail_view.dart');
}

// 2. Manager Game Details View
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
  const endSectionIdx = mGameViewContent.indexOf('  Widget _buildRevenueSummaryCard', gameCctvIdx);
  if (endSectionIdx !== -1) {
    const commentIdx = mGameViewContent.lastIndexOf('  ///', gameCctvIdx);
    const replaceStart = (commentIdx !== -1 && commentIdx > gameCctvIdx - 50) ? commentIdx : gameCctvIdx;
    mGameViewContent = mGameViewContent.slice(0, replaceStart) + newGameCctvSection + '\n\n' + mGameViewContent.slice(endSectionIdx);
    fs.writeFileSync(mGameViewPath, mGameViewContent, 'utf8');
    console.log('✓ Updated manager_game_details_view.dart');
  }
}

// 3. Game Details Controller
const gCtrlPath = path.resolve('../lib/modules/games/controllers/game_details_controller.dart');
let gCtrlContent = fs.readFileSync(gCtrlPath, 'utf8');

if (!gCtrlContent.includes('final Rxn<VideoModel> selectedVideo')) {
  gCtrlContent = gCtrlContent.replace(
    '  final RxList<VideoModel> matchVideos = <VideoModel>[].obs;',
    '  final RxList<VideoModel> matchVideos = <VideoModel>[].obs;\n  final Rxn<VideoModel> selectedVideo = Rxn<VideoModel>();'
  );

  gCtrlContent = gCtrlContent.replace(
    'matchVideos.value = vids;',
    'matchVideos.value = vids;\n        if (vids.isNotEmpty) selectedVideo.value = vids.first;'
  );

  gCtrlContent = gCtrlContent.replace(
    '  bool get isManagerOrAdmin {',
    `  void selectCamera(VideoModel video) {
    selectedVideo.value = video;
  }

  bool get isManagerOrAdmin {`
  );

  fs.writeFileSync(gCtrlPath, gCtrlContent, 'utf8');
  console.log('✓ Updated game_details_controller.dart');
}

// 4. Game Details View
const gViewPath = path.resolve('../lib/modules/games/views/game_details_view.dart');
let gViewContent = fs.readFileSync(gViewPath, 'utf8');

const newPlayerVidSec = fs.readFileSync('scratch/video_section_game_details.dart', 'utf8');
const vidSecIdx = gViewContent.indexOf('Widget _buildVideoSection(');
if (vidSecIdx !== -1) {
  const endVidSecIdx = gViewContent.indexOf('  Widget _buildRefundAuditSection', vidSecIdx);
  if (endVidSecIdx !== -1) {
    gViewContent = gViewContent.slice(0, vidSecIdx) + newPlayerVidSec + '\n\n' + gViewContent.slice(endVidSecIdx);
    fs.writeFileSync(gViewPath, gViewContent, 'utf8');
    console.log('✓ Updated game_details_view.dart');
  }
}

// 5. Video Player Controller & View
fs.copyFileSync('scratch/video_player_controller.dart', '../lib/modules/videos/controllers/video_player_controller.dart');
console.log('✓ Updated video_player_controller.dart');

fs.copyFileSync('scratch/video_player_view.dart', '../lib/modules/videos/views/video_player_view.dart');
console.log('✓ Updated video_player_view.dart');

console.log('ALL FRONTEND UPDATES APPLIED SUCCESSFULLY!');
