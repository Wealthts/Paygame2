const express = require('express');
const router = express.Router();

const gameController = require('../controller/game_controller');
const { verifyToken, verifyAdmin } = require('../middleware/auth');

// Get all games
router.get('/', verifyToken, gameController.getAllGames);

// Get all games by admin
router.get('/all', verifyToken,verifyAdmin, gameController.getAllGamesAdmin);

// Get game by ID
router.get('/:id', verifyToken, gameController.getGameById);

// Create game (Admin only)
router.post('/', verifyToken, verifyAdmin, gameController.createGame);

// Update game (Admin only)
router.put('/:id', verifyToken, verifyAdmin, gameController.updateGame);

// Delete game (Admin only) (Soft delete)
router.patch('/soft/:id', verifyToken, verifyAdmin, gameController.softDeleteGame);

// Delete game (Admin only) (Hard delete)
router.delete('/hard/:id', verifyToken, verifyAdmin, gameController.hardDeleteGame);

module.exports = router;