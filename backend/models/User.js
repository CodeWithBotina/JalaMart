// models/User.js
const db = require('../config/db');
const bcrypt = require('bcryptjs');

class User {
  static async getByEmail(email) {
    const { rows } = await db.query(
      'SELECT * FROM seguridad.usuario WHERE email = $1',
      [email]
    );
    return rows[0];
  }

  static async create(userData) {
    const hashedPassword = await bcrypt.hash(userData.password, 10);
    const { rows } = await db.query(
      `INSERT INTO seguridad.usuario (
        email, password_hash, rol
      ) VALUES ($1, $2, $3) RETURNING *`,
      [userData.email, hashedPassword, userData.role || 'user']
    );
    return rows[0];
  }

  static async comparePassword(candidatePassword, hashedPassword) {
    return await bcrypt.compare(candidatePassword, hashedPassword);
  }

  static async updateLastLogin(userId) {
    await db.query(
      'UPDATE seguridad.usuario SET ultimo_login = NOW() WHERE id_usuario = $1',
      [userId]
    );
  }
}

module.exports = User;