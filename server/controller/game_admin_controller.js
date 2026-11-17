
const db = require('../db_config');

// ==========================================
// Helpers
// ==========================================
function parsePositiveId(value) {
    const id = Number(value);

    return Number.isSafeInteger(id) && id > 0
        ? id
        : null;
}

function parseFlag(value) {
    if (value === true || value === 1 || value === '1') {
        return 1;
    }

    if (value === false || value === 0 || value === '0') {
        return 0;
    }

    return null;
}

function validateGame(body) {
    const gameName = typeof body.game_name === 'string'
        ? body.game_name.trim()
        : '';

    const category = typeof body.category === 'string'
        ? body.category.trim()
        : '';

    const uidPattern = typeof body.uid_pattern === 'string'
        ? body.uid_pattern.trim()
        : '';

    const imageUrl = typeof body.image_url === 'string'
        ? body.image_url.trim()
        : '';

    const requiresServer = parseFlag(body.requires_server);
    const isActive = body.is_active === undefined
        ? 1
        : parseFlag(body.is_active);

    if (
        !gameName ||
        gameName.length > 100 ||
        !category ||
        category.length > 100 ||
        !uidPattern ||
        uidPattern.length > 100 ||
        imageUrl.length > 255 ||
        requiresServer === null ||
        isActive === null
    ) {
        return null;
    }

    return {
        game_name: gameName,
        category,
        uid_pattern: uidPattern,
        requires_server: requiresServer,
        image_url: imageUrl,
        is_active: isActive
    };
}

// ==========================================
// Get All Games (Admin)
// ==========================================
async function getAllGames(req, res) {
    try {
        const [rows] = await db.promise().query(
            `SELECT
                game_id,
                game_name,
                category,
                uid_pattern,
                requires_server,
                image_url,
                is_active
             FROM games
             ORDER BY game_id ASC`
        );

        return res.status(200).json({
            games: rows
        });

    } catch (error) {
        console.error('Admin Get Games Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// ==========================================
// Create Game (Admin)
// ==========================================
async function createGame(req, res) {
    const game = validateGame(req.body || {});

    if (!game) {
        return res.status(400).json({
            message: 'Invalid game information'
        });
    }

    try {
        const [result] = await db.promise().query(
            `INSERT INTO games (
                game_name,
                category,
                uid_pattern,
                requires_server,
                image_url,
                is_active
            )
            VALUES (?, ?, ?, ?, ?, ?)`,
            [
                game.game_name,
                game.category,
                game.uid_pattern,
                game.requires_server,
                game.image_url,
                game.is_active
            ]
        );

        const [rows] = await db.promise().query(
            `SELECT
                game_id,
                game_name,
                category,
                uid_pattern,
                requires_server,
                image_url,
                is_active
             FROM games
             WHERE game_id = ?`,
            [result.insertId]
        );

        return res.status(201).json({
            message: 'Game created successfully',
            game: rows[0]
        });

    } catch (error) {
        console.error('Create Game Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// ==========================================
// Update Game (Admin)
// ==========================================
async function updateGame(req, res) {
    const gameId = parsePositiveId(req.params.id);
    const game = validateGame(req.body || {});

    if (!gameId) {
        return res.status(400).json({
            message: 'Invalid game ID'
        });
    }

    if (!game) {
        return res.status(400).json({
            message: 'Invalid game information'
        });
    }

    try {
        const [existing] = await db.promise().query(
            `SELECT game_id
             FROM games
             WHERE game_id = ?`,
            [gameId]
        );

        if (existing.length === 0) {
            return res.status(404).json({
                message: 'Game not found'
            });
        }

        await db.promise().query(
            `UPDATE games
             SET game_name = ?,
                 category = ?,
                 uid_pattern = ?,
                 requires_server = ?,
                 image_url = ?,
                 is_active = ?
             WHERE game_id = ?`,
            [
                game.game_name,
                game.category,
                game.uid_pattern,
                game.requires_server,
                game.image_url,
                game.is_active,
                gameId
            ]
        );

        const [rows] = await db.promise().query(
            `SELECT
                game_id,
                game_name,
                category,
                uid_pattern,
                requires_server,
                image_url,
                is_active
             FROM games
             WHERE game_id = ?`,
            [gameId]
        );

        return res.status(200).json({
            message: 'Game updated successfully',
            game: rows[0]
        });

    } catch (error) {
        console.error('Update Game Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// ==========================================
// Update Game Status (Admin)
// ==========================================
async function updateGameStatus(req, res) {
    const gameId = parsePositiveId(req.params.id);
    const isActive = parseFlag(req.body?.is_active);

    if (!gameId) {
        return res.status(400).json({
            message: 'Invalid game ID'
        });
    }

    if (isActive === null) {
        return res.status(400).json({
            message: 'Invalid game status'
        });
    }

    try {
        const [result] = await db.promise().query(
            `UPDATE games
             SET is_active = ?
             WHERE game_id = ?`,
            [isActive, gameId]
        );

        if (result.affectedRows === 0) {
            const [rows] = await db.promise().query(
                `SELECT game_id
                 FROM games
                 WHERE game_id = ?`,
                [gameId]
            );

            if (rows.length === 0) {
                return res.status(404).json({
                    message: 'Game not found'
                });
            }
        }

        return res.status(200).json({
            message: 'Game status updated successfully',
            game_id: gameId,
            is_active: isActive
        });

    } catch (error) {
        console.error('Update Game Status Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

module.exports = {
    getAllGames,
    createGame,
    updateGame,
    updateGameStatus
};
