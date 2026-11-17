
const db = require('../db_config');

// ตรวจสอบ ID จำนวนเต็มบวก
function parsePositiveId(value) {
    if (
        typeof value !== 'number' &&
        typeof value !== 'string'
    ) {
        return null;
    }

    if (
        typeof value === 'string' &&
        !/^\d+$/.test(value.trim())
    ) {
        return null;
    }

    const number = Number(value);

    return Number.isSafeInteger(number) && number > 0
        ? number
        : null;
}

// ตรวจสอบจำนวนเต็มที่ไม่น้อยกว่า 0
function parseNonNegativeInt(value) {
    if (
        typeof value !== 'number' &&
        typeof value !== 'string'
    ) {
        return null;
    }

    if (
        typeof value === 'string' &&
        !/^\d+$/.test(value.trim())
    ) {
        return null;
    }

    const number = Number(value);

    return Number.isSafeInteger(number) && number >= 0
        ? number
        : null;
}

// ตรวจสอบราคา
function parsePrice(value) {
    if (
        typeof value !== 'number' &&
        typeof value !== 'string'
    ) {
        return null;
    }

    if (
        typeof value === 'string' &&
        value.trim() === ''
    ) {
        return null;
    }

    const number = Number(value);

    return Number.isFinite(number) && number > 0
        ? number
        : null;
}

// ตรวจสอบค่า tinyint 0 หรือ 1
function parseTinyInt(value) {
    if (
        value === 0 ||
        value === '0' ||
        value === false
    ) {
        return 0;
    }

    if (
        value === 1 ||
        value === '1' ||
        value === true
    ) {
        return 1;
    }

    return null;
}

// ตรวจสอบชื่อ Package
function parsePackageName(value) {
    if (typeof value !== 'string') {
        return null;
    }

    const name = value.trim();

    if (!name || name.length > 100) {
        return null;
    }

    return name;
}

// ตรวจสอบว่า Game มีอยู่และเปิดใช้งาน
async function isActiveGame(gameId) {
    const [games] = await db.promise().query(
        `SELECT game_id
         FROM games
         WHERE game_id = ?
         AND is_active = 1`,
        [gameId]
    );

    return games.length > 0;
}

// User: ดูเฉพาะ Package ที่เปิดใช้งาน
async function getAllPackages(req, res) {
    try {
        // รับ game_id จาก Query String (ถ้ามี)
        let gameId = null;

        if (req.query.game_id !== undefined) {
            gameId = parsePositiveId(req.query.game_id);

            if (!gameId) {
                return res.status(400).json({
                    message: 'Invalid game ID'
                });
            }
        }

        let sql = `
            SELECT
                p.package_id,
                p.game_id,
                g.game_name,
                g.requires_server,
                p.package_name,
                p.price,
                p.is_active
            FROM packages p
            INNER JOIN games g
                ON p.game_id = g.game_id
            WHERE p.is_active = 1
            AND g.is_active = 1
        `;

        const params = [];

        // ถ้าระบุ game_id ให้แสดงเฉพาะแพ็กเกจของเกมนั้น
        if (gameId !== null) {
            sql += ' AND p.game_id = ?';
            params.push(gameId);
        }

        sql += ' ORDER BY p.package_id DESC';

        const [packages] = await db.promise().query(
            sql,
            params
        );

        return res.status(200).json(packages);

    } catch (error) {
        console.error('Get Packages Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// Admin: ดู Package ทั้งหมด
async function getAllPackagesAdmin(req, res) {
    try {
        const [packages] = await db.promise().query(
            `SELECT
                p.package_id,
                p.game_id,
                g.game_name,
                p.package_name,
                p.price,
                p.reward_points,
                p.is_active,
                g.is_active AS game_is_active
             FROM packages p
             INNER JOIN games g
                ON p.game_id = g.game_id
             ORDER BY p.package_id DESC`
        );

        return res.status(200).json(packages);

    } catch (error) {
        console.error('Get All Packages Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// ดู Package ตาม ID
async function getPackageById(req, res) {
    try {
        const packageId = parsePositiveId(req.params.id);

        if (!packageId) {
            return res.status(400).json({
                message: 'Invalid package ID'
            });
        }

        let sql = `
            SELECT
                p.package_id,
                p.game_id,
                g.game_name,
                p.package_name,
                p.price,
                p.reward_points,
                p.is_active,
                g.is_active AS game_is_active
            FROM packages p
            INNER JOIN games g
                ON p.game_id = g.game_id
            WHERE p.package_id = ?
        `;

        const values = [packageId];

        // User เห็นเฉพาะ Package และ Game ที่ Active
        if (req.user.role !== 'admin') {
            sql += `
                AND p.is_active = 1
                AND g.is_active = 1
            `;
        }

        const [packages] = await db.promise().query(
            sql,
            values
        );

        if (packages.length === 0) {
            return res.status(404).json({
                message: 'Package not found'
            });
        }

        return res.status(200).json(packages[0]);

    } catch (error) {
        console.error('Get Package Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// Admin: สร้าง Package
async function createPackage(req, res) {
    try {
        const body = req.body || {};

        const gameId = parsePositiveId(body.game_id);
        const packageName = parsePackageName(
            body.package_name
        );
        const price = parsePrice(body.price);

        const rewardPoints = body.reward_points === undefined
            ? 0
            : parseNonNegativeInt(body.reward_points);

        const isActive = body.is_active === undefined
            ? 1
            : parseTinyInt(body.is_active);

        if (
            !gameId ||
            !packageName ||
            price === null ||
            rewardPoints === null ||
            isActive === null
        ) {
            return res.status(400).json({
                message: 'Invalid package information'
            });
        }

        // ตรวจสอบ Game
        const gameExists = await isActiveGame(gameId);

        if (!gameExists) {
            return res.status(400).json({
                message: 'Game not found or inactive'
            });
        }

        const [result] = await db.promise().query(
            `INSERT INTO packages (
                game_id,
                package_name,
                price,
                reward_points,
                is_active
            )
            VALUES (?, ?, ?, ?, ?)`,
            [
                gameId,
                packageName,
                price,
                rewardPoints,
                isActive
            ]
        );

        return res.status(201).json({
            message: 'Package created successfully',
            package_id: result.insertId
        });

    } catch (error) {
        console.error('Create Package Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// Admin: แก้ไข Package
async function updatePackage(req, res) {
    try {
        const packageId = parsePositiveId(req.params.id);

        if (!packageId) {
            return res.status(400).json({
                message: 'Invalid package ID'
            });
        }

        const body = req.body || {};

        // ตรวจสอบ Package เดิม
        const [existingPackages] = await db.promise().query(
            `SELECT *
             FROM packages
             WHERE package_id = ?`,
            [packageId]
        );

        if (existingPackages.length === 0) {
            return res.status(404).json({
                message: 'Package not found'
            });
        }

        const existing = existingPackages[0];

        // ถ้าไม่ได้ส่ง field มา ให้ใช้ค่าเดิม
        const gameId = body.game_id === undefined
            ? Number(existing.game_id)
            : parsePositiveId(body.game_id);

        const packageName = body.package_name === undefined
            ? existing.package_name
            : parsePackageName(body.package_name);

        const price = body.price === undefined
            ? Number(existing.price)
            : parsePrice(body.price);

        const rewardPoints = body.reward_points === undefined
            ? Number(existing.reward_points)
            : parseNonNegativeInt(body.reward_points);

        const isActive = body.is_active === undefined
            ? Number(existing.is_active)
            : parseTinyInt(body.is_active);

        if (
            !gameId ||
            !packageName ||
            price === null ||
            !Number.isFinite(price) ||
            rewardPoints === null ||
            isActive === null
        ) {
            return res.status(400).json({
                message: 'Invalid package information'
            });
        }

        // ต้องตรวจสอบ Game เมื่อเปลี่ยน Game
        // หรือกำลังเปิดใช้งาน Package
        const gameChanged =
            gameId !== Number(existing.game_id);

        if (gameChanged || isActive === 1) {
            const gameExists = await isActiveGame(gameId);

            if (!gameExists) {
                return res.status(400).json({
                    message: 'Game not found or inactive'
                });
            }
        }

        await db.promise().query(
            `UPDATE packages
             SET
                game_id = ?,
                package_name = ?,
                price = ?,
                reward_points = ?,
                is_active = ?
             WHERE package_id = ?`,
            [
                gameId,
                packageName,
                price,
                rewardPoints,
                isActive,
                packageId
            ]
        );

        return res.status(200).json({
            message: 'Package updated successfully'
        });

    } catch (error) {
        console.error('Update Package Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// Admin: ปิดใช้งาน Package (Soft Delete)
async function softDeletePackage(req, res) {
    try {
        const packageId = parsePositiveId(req.params.id);

        if (!packageId) {
            return res.status(400).json({
                message: 'Invalid package ID'
            });
        }

        const [result] = await db.promise().query(
            `UPDATE packages
             SET is_active = 0
             WHERE package_id = ?`,
            [packageId]
        );

        if (result.affectedRows === 0) {
            const [packages] = await db.promise().query(
                `SELECT package_id
                 FROM packages
                 WHERE package_id = ?`,
                [packageId]
            );

            if (packages.length === 0) {
                return res.status(404).json({
                    message: 'Package not found'
                });
            }
        }

        return res.status(200).json({
            message: 'Package deactivated successfully'
        });

    } catch (error) {
        console.error('Soft Delete Package Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// Admin: ลบ Package ออกจากฐานข้อมูลจริง
async function hardDeletePackage(req, res) {
    try {
        const packageId = parsePositiveId(req.params.id);

        if (!packageId) {
            return res.status(400).json({
                message: 'Invalid package ID'
            });
        }

        const [result] = await db.promise().query(
            `DELETE FROM packages
             WHERE package_id = ?`,
            [packageId]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({
                message: 'Package not found'
            });
        }

        return res.status(200).json({
            message: 'Package deleted successfully'
        });

    } catch (error) {
        // Package ที่มี Order อ้างอิงอยู่จะลบจริงไม่ได้
        if (error.code === 'ER_ROW_IS_REFERENCED_2') {
            return res.status(409).json({
                message: 'Cannot delete package because it is used by orders'
            });
        }

        console.error('Hard Delete Package Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

module.exports = {
    getAllPackages,
    getAllPackagesAdmin,
    getPackageById,
    createPackage,
    updatePackage,
    softDeletePackage,
    hardDeletePackage
};
