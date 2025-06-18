// models/Category.js
const db = require('../config/db');

class Category {
  static async getAll() {
    const { rows } = await db.query(
      'SELECT * FROM comercial.categoria WHERE activa = true ORDER BY nombre'
    );
    return rows;
  }

  static async getById(id) {
    const { rows } = await db.query(
      'SELECT * FROM comercial.categoria WHERE id_categoria = $1 AND activa = true', 
      [id]
    );
    return rows[0];
  }

  static async create({ nombre, descripcion, slug, imagen_url }) {
    const { rows } = await db.query(
      `INSERT INTO comercial.categoria 
       (nombre, descripcion, slug, imagen_url) 
       VALUES ($1, $2, $3, $4) 
       RETURNING *`,
      [nombre, descripcion, slug, imagen_url]
    );
    return rows[0];
  }

  static async update(id, { nombre, descripcion, slug, imagen_url, activa }) {
    const { rows } = await db.query(
      `UPDATE comercial.categoria SET
        nombre = $1, descripcion = $2, 
        slug = $3, imagen_url = $4, activa = $5
       WHERE id_categoria = $6 
       RETURNING *`,
      [nombre, descripcion, slug, imagen_url, activa, id]
    );
    return rows[0];
  }

  static async delete(id) {
    const { rows } = await db.query(
      `UPDATE comercial.categoria SET activa = false 
       WHERE id_categoria = $1 
       RETURNING *`,
      [id]
    );
    return rows[0];
  }

  static async getProducts(categoryId) {
    const { rows } = await db.query(
      `SELECT p.* FROM comercial.producto p
       WHERE p.id_categoria = $1 AND p.activo = true`,
      [categoryId]
    );
    return rows;
  }
}

module.exports = Category;