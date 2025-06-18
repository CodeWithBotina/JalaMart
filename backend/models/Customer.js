// models/Customer.js
const db = require('../config/db');
const bcrypt = require('bcryptjs');

class Customer {
  static async getById(id) {
    const { rows } = await db.query(
      'SELECT * FROM comercial.cliente WHERE id_cliente = $1',
      [id]
    );
    return rows[0];
  }

  static async getByEmail(email) {
    const { rows } = await db.query(
      'SELECT * FROM comercial.cliente WHERE email = $1',
      [email]
    );
    return rows[0];
  }

  static async create(customerData) {
    const { rows } = await db.query(
      `INSERT INTO comercial.cliente (
        nombre, apellido, email, direccion, telefono
      ) VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [
        customerData.nombre,
        customerData.apellido,
        customerData.email,
        customerData.direccion,
        customerData.telefono
      ]
    );
    
    // Hash password and create user
    const hashedPassword = await bcrypt.hash(customerData.password, 10);
    await db.query(
      `INSERT INTO seguridad.usuario (
        email, password_hash, id_cliente
      ) VALUES ($1, $2, $3)`,
      [customerData.email, hashedPassword, rows[0].id_cliente]
    );
    
    return rows[0];
  }

  static async update(id, customerData) {
    const { rows } = await db.query(
      `UPDATE comercial.cliente SET
        nombre = $1, apellido = $2,
        direccion = $3, telefono = $4
       WHERE id_cliente = $5
       RETURNING *`,
      [
        customerData.nombre,
        customerData.apellido,
        customerData.direccion,
        customerData.telefono,
        id
      ]
    );
    return rows[0];
  }

  static async updatePassword(id, currentPassword, newPassword) {
    // Verify current password
    const { rows } = await db.query(
      `SELECT u.password_hash 
       FROM seguridad.usuario u
       JOIN comercial.cliente c ON u.id_cliente = c.id_cliente
       WHERE c.id_cliente = $1`,
      [id]
    );
    
    if (!rows[0]) {
      throw new Error('User not found');
    }
    
    const isMatch = await bcrypt.compare(currentPassword, rows[0].password_hash);
    if (!isMatch) {
      throw new Error('Current password is incorrect');
    }
    
    // Update password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await db.query(
      'UPDATE seguridad.usuario SET password_hash = $1 WHERE id_cliente = $2',
      [hashedPassword, id]
    );
    
    return { success: true };
  }
}

module.exports = Customer;