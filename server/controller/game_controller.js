const db = require('../db_config');

// Validate positive integer ID
function isValidId(value) {
    const id = Number(value);
    return Number.isInteger(id) && id > 0;
}

// Convert boolean or 0/1 to database tinyint
function toTinyInt(value) {
    if (value === true || value === 1 || value === '1') return 1;
    if (value === false || value === 0 || value === '0') return 0;
    return null;
}

// Get all games
async function getAllGames(req, res) {
    try {
        // ลูกค้าจะเห็นเฉพาะเกมที่เปิดใช้งาน
        // ส่วน Admin สามารถเห็นเกมทั้งหมดได้
        const statusFilter = req.user.role === 'admin'
            ? ''
            : 'WHERE is_active = 1';

        const [games] = await db.promise().query(
            `SELECT
                game_id,
                game_name,
                category,
                uid_pattern,
                requires_server,
                image_url,
                is_active
             FROM games
             ${statusFilter}
             ORDER BY game_id DESC`
        );

        return res.status(200).json({
            games: games
        });

    } catch (error) {
        console.error('Get Games Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// Get all game by admin
async function getAllGamesAdmin(req, res) {
    try {
        const [games] = await db.promise().query(
            `SELECT *
             FROM games
             ORDER BY game_id DESC`
        );

        return res.status(200).json({
            games: games
        });

    } catch (error) {
        console.error('Get All Admin Games Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// Get game by ID
async function getGameById(req, res) {
    try {
        const gameId = Number(req.params.id);

        if (!isValidId(gameId)) {
            return res.status(400).json({
                message: 'Invalid game ID'
            });
        }

        const [games] = await db.promise().query(
            `SELECT *
             FROM games
             WHERE game_id = ?`,
            [gameId]
        );

        if (games.length === 0) {
            return res.status(404).json({
                message: 'Game not found'
            });
        }

        return res.status(200).json({ game: games[0] });

    } catch (error) {
        console.error('Get Game By ID Error:', error);
        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// POST add new game
async function createGame(req, res) {
    try {
        const { game_name, category, uid_pattern, requires_server, image_url, is_active } = req.body || {};

        const gameName = typeof game_name === 'string' ? game_name.trim() : '';
        const gameCategory = typeof category === 'string' ? category.trim() : '';
        const uidPattern = typeof uid_pattern === 'string' ? uid_pattern.trim() : '';
        const imageUrl = typeof image_url === 'string' ? image_url.trim() : null;

        const requiresServer = toTinyInt(requires_server);
        const activeStatus = toTinyInt(is_active);

        if (
            !gameName || gameName.length > 100 ||
            !gameCategory || gameCategory.length > 100 ||
            !uidPattern || uidPattern.length > 100 ||
            imageUrl === null || imageUrl.length > 255 ||
            requiresServer === null || activeStatus === null
        ) {
            return res.status(400).json({
                message: 'Invalid game data'
            });
        }

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
            [gameName, gameCategory, uidPattern, requiresServer, imageUrl, activeStatus]
        );

        return res.status(201).json({
            message: 'Game created successfully',
            game_id: result.insertId
        });

    } catch (error) {
        console.error('Create Game Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// PUT update game
async function updateGame(req, res) {
    try {
        const gameId = Number(req.params.id);

        const { game_name, category, uid_pattern, requires_server, image_url, is_active } = req.body || {};

        const gameName = typeof game_name === 'string' ? game_name.trim() : '';
        const gameCategory = typeof category === 'string' ? category.trim() : '';
        const uidPattern = typeof uid_pattern === 'string' ? uid_pattern.trim() : '';
        const imageUrl = typeof image_url === 'string' ? image_url.trim() : null;

        const requiresServer = toTinyInt(requires_server);
        const activeStatus = toTinyInt(is_active);

        if (
            !isValidId(gameId) || !gameName ||
            gameName.length > 100 || !gameCategory ||
            gameCategory.length > 100 || !uidPattern ||
            uidPattern.length > 100 || imageUrl === null ||
            imageUrl.length > 255 || requiresServer === null ||
            activeStatus === null
        ) {
            return res.status(400).json({
                message: 'Invalid game data'
            });
        }

        const [games] = await db.promise().query(
            `SELECT game_id
             FROM games
             WHERE game_id = ?`,
            [gameId]
        );

        if (games.length === 0) {
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
                gameName,
                gameCategory,
                uidPattern,
                requiresServer,
                imageUrl,
                activeStatus,
                gameId
            ]
        );

        return res.status(200).json({
            message: 'Game updated successfully'
        });

    } catch (error) {
        console.error('Update Game Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// Delete game (soft delete)
async function softDeleteGame(req, res) {
    try {
        const gameId = Number(req.params.id);

        if (!isValidId(gameId)) {
            return res.status(400).json({
                message: 'Invalid game ID'
            });
        }

        const [result] = await db.promise().query(
            `UPDATE games
             SET is_active = 0
             WHERE game_id = ?
             AND is_active = 1`,
            [gameId]
        );

        if (result.affectedRows === 0) {
            const [games] = await db.promise().query(
                `SELECT game_id
                 FROM games
                 WHERE game_id = ?`,
                [gameId]
            );

            if (games.length === 0) {
                return res.status(404).json({
                    message: 'Game not found'
                });
            }

            return res.status(200).json({
                message: 'Game already inactive'
            });
        }

        return res.status(200).json({
            message: 'Game deactivated successfully'
        });

    } catch (error) {
        console.error('Soft Delete Game Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// Delete game (hard delete)
async function hardDeleteGame(req, res) {
    try {
        const gameId = Number(req.params.id);

        if (!isValidId(gameId)) {
            return res.status(400).json({
                message: 'Invalid game ID'
            });
        }

        const [games] = await db.promise().query(
            `SELECT game_id
             FROM games
             WHERE game_id = ?`,
            [gameId]
        );

        if (games.length === 0) {
            return res.status(404).json({
                message: 'Game not found'
            });
        }

        const [packages] = await db.promise().query(
            `SELECT package_id
             FROM packages
             WHERE game_id = ?
             LIMIT 1`,
            [gameId]
        );

        if (packages.length > 0) {
            return res.status(409).json({
                message: 'Cannot delete game because packages are linked to this game'
            });
        }

        await db.promise().query(
            `DELETE FROM games
             WHERE game_id = ?`,
            [gameId]
        );

        return res.status(200).json({
            message: 'Game deleted successfully'
        });

    } catch (error) {
        console.error('Hard Delete Game Error:', error);

        if (
            error.code === 'ER_ROW_IS_REFERENCED_2' ||
            error.code === 'ER_ROW_IS_REFERENCED'
        ) {
            return res.status(409).json({
                message: 'Cannot delete game because it is referenced by other records'
            });
        }

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

module.exports = { getAllGames, getAllGamesAdmin, getGameById, createGame, updateGame, hardDeleteGame, softDeleteGame };