
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

function validatePackage(body) {
    const gameId = parsePositiveId(body.game_id);

    const packageName = typeof body.package_name === 'string'
        ? body.package_name.trim()
        : '';

    const price = Number(body.price);

    const isActive = body.is_active === undefined
        ? 1
        : parseFlag(body.is_active);

    if (
        !gameId ||
        !packageName ||
        packageName.length > 100 ||
        !Number.isFinite(price) ||
        price <= 0 ||
        price > 99999999.99 ||
        Math.round(price * 100) / 100 !== price ||
        isActive === null
    ) {
        return null;
    }

    return {
        game_id: gameId,
        package_name: packageName,
        price,
        is_active: isActive
    };
}

// ==========================================
// Get All Packages (Admin)
// ==========================================
async function getAllPackages(req, res) {
    try {
        const [rows] = await db.promise().query(
            `SELECT
                p.package_id,
                p.game_id,
                p.package_name,
                p.price,
                p.is_active,
                g.game_name,
                g.requires_server,
                g.is_active AS game_active
             FROM packages p
             INNER JOIN games g
                ON p.game_id = g.game_id
             ORDER BY p.package_id ASC`
        );

        return res.status(200).json({
            packages: rows
        });

    } catch (error) {
        console.error('Get All Packages Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// ==========================================
// Check Game
// ==========================================
async function checkGame(gameId, isActive) {
    const [rows] = await db.promise().query(
        `SELECT game_id, is_active
         FROM games
         WHERE game_id = ?`,
        [gameId]
    );

    if (rows.length === 0) {
        const error = new Error('Game not found');
        error.statusCode = 404;
        throw error;
    }

    if (
        isActive === 1 &&
        Number(rows[0].is_active) !== 1
    ) {
        const error = new Error(
            'Cannot activate package because game is inactive'
        );
        error.statusCode = 409;
        throw error;
    }
}

// ==========================================
// Create Package (Admin)
// ==========================================
async function createPackage(req, res) {
    const data = validatePackage(req.body || {});

    if (!data) {
        return res.status(400).json({
            message: 'Invalid package information'
        });
    }

    try {
        await checkGame(data.game_id, data.is_active);

        const [result] = await db.promise().query(
            `INSERT INTO packages (
                game_id,
                package_name,
                price,
                is_active
            )
            VALUES (?, ?, ?, ?)`,
            [
                data.game_id,
                data.package_name,
                data.price,
                data.is_active
            ]
        );

        const [rows] = await db.promise().query(
            `SELECT
                p.package_id,
                p.game_id,
                p.package_name,
                p.price,
                p.is_active,
                g.game_name,
                g.requires_server,
                g.is_active AS game_active
             FROM packages p
             INNER JOIN games g
                ON p.game_id = g.game_id
             WHERE p.package_id = ?`,
            [result.insertId]
        );

        return res.status(201).json({
            message: 'Package created successfully',
            package: rows[0]
        });

    } catch (error) {
        console.error('Create Package Error:', error);

        return res.status(error.statusCode || 500).json({
            message: error.statusCode
                ? error.message
                : 'Internal server error'
        });
    }
}

// ==========================================
// Update Package (Admin)
// ==========================================
async function updatePackage(req, res) {
    const packageId = parsePositiveId(req.params.id);
    const data = validatePackage(req.body || {});

    if (!packageId) {
        return res.status(400).json({
            message: 'Invalid package ID'
        });
    }

    if (!data) {
        return res.status(400).json({
            message: 'Invalid package information'
        });
    }

    try {
        const [existing] = await db.promise().query(
            `SELECT package_id
             FROM packages
             WHERE package_id = ?`,
            [packageId]
        );

        if (existing.length === 0) {
            return res.status(404).json({
                message: 'Package not found'
            });
        }

        await checkGame(data.game_id, data.is_active);

        await db.promise().query(
            `UPDATE packages
             SET game_id = ?,
                 package_name = ?,
                 price = ?,
                 is_active = ?
             WHERE package_id = ?`,
            [
                data.game_id,
                data.package_name,
                data.price,
                data.is_active,
                packageId
            ]
        );

        const [rows] = await db.promise().query(
            `SELECT
                p.package_id,
                p.game_id,
                p.package_name,
                p.price,
                p.is_active,
                g.game_name,
                g.requires_server,
                g.is_active AS game_active
             FROM packages p
             INNER JOIN games g
                ON p.game_id = g.game_id
             WHERE p.package_id = ?`,
            [packageId]
        );

        return res.status(200).json({
            message: 'Package updated successfully',
            package: rows[0]
        });

    } catch (error) {
        console.error('Update Package Error:', error);

        return res.status(error.statusCode || 500).json({
            message: error.statusCode
                ? error.message
                : 'Internal server error'
        });
    }
}

// ==========================================
// Update Package Status (Admin)
// ==========================================
async function updatePackageStatus(req, res) {
    const packageId = parsePositiveId(req.params.id);
    const isActive = parseFlag(req.body?.is_active);

    if (!packageId) {
        return res.status(400).json({
            message: 'Invalid package ID'
        });
    }

    if (isActive === null) {
        return res.status(400).json({
            message: 'Invalid package status'
        });
    }

    try {
        const [rows] = await db.promise().query(
            `SELECT package_id, game_id
             FROM packages
             WHERE package_id = ?`,
            [packageId]
        );

        if (rows.length === 0) {
            return res.status(404).json({
                message: 'Package not found'
            });
        }

        if (isActive === 1) {
            await checkGame(rows[0].game_id, 1);
        }

        await db.promise().query(
            `UPDATE packages
             SET is_active = ?
             WHERE package_id = ?`,
            [isActive, packageId]
        );

        return res.status(200).json({
            message: 'Package status updated successfully',
            package_id: packageId,
            is_active: isActive
        });

    } catch (error) {
        console.error('Update Package Status Error:', error);

        return res.status(error.statusCode || 500).json({
            message: error.statusCode
                ? error.message
                : 'Internal server error'
        });
    }
}

module.exports = {
    getAllPackages,
    createPackage,
    updatePackage,
    updatePackageStatus
};
