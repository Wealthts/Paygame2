
const express = require('express');
const router = express.Router();

const gameAdminController = require(
    '../controller/game_admin_controller'
);

const {
    verifyToken,
    verifyAdmin
} = require('../middleware/auth');

// ทุก Route ต้องเป็น Admin
router.use(verifyToken, verifyAdmin);

// GET /api/admin/games
router.get('/', gameAdminController.getAllGames);

// POST /api/admin/games
router.post('/', gameAdminController.createGame);

// PUT /api/admin/games/:id
router.put('/:id', gameAdminController.updateGame);

// PATCH /api/admin/games/:id/status
router.patch('/:id/status', gameAdminController.updateGameStatus);

module.exports = router;
