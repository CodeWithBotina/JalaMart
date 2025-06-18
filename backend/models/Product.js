// models/Product.js
const db = require('../config/db');

class Product {
  static async getAll() {
    const { rows } = await db.query(
      `SELECT p.*, c.nombre as categoria_nombre 
       FROM comercial.producto p
       JOIN comercial.categoria c ON p.id_categoria = c.id_categoria
       WHERE p.activo = true`
    );
    return rows;
  }

  static async getById(id) {
    const { rows } = await db.query(
      `SELECT p.*, c.nombre as categoria_nombre 
       FROM comercial.producto p
       JOIN comercial.categoria c ON p.id_categoria = c.id_categoria
       WHERE p.id_producto = $1 AND p.activo = true`,
      [id]
    );
    return rows[0];
  }

  static async getByCategory(categoryId) {
    const { rows } = await db.query(
      `SELECT * FROM comercial.producto 
       WHERE id_categoria = $1 AND activo = true`,
      [categoryId]
    );
    return rows;
  }

  static async getFeatured() {
    const { rows } = await db.query(
      'SELECT * FROM reportes.productos_recientes LIMIT 6'
    );
    return rows;
  }

  static async getDiscounted() {
    const { rows } = await db.query(
      'SELECT * FROM reportes.mejores_ofertas LIMIT 10'
    );
    return rows;
  }

  static async search(query) {
    const { rows } = await db.query(
      'SELECT * FROM comercial.buscar_productos($1)',
      [query]
    );
    return rows;
  }

  static async create(productData) {
    const { rows } = await db.query(
      `INSERT INTO comercial.producto (
        nombre, descripcion, precio, precio_descuento,
        id_categoria, id_proveedor, stock, sku, imagen_url
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *`,
      [
        productData.nombre,
        productData.descripcion,
        productData.precio,
        productData.precio_descuento,
        productData.id_categoria,
        productData.id_proveedor,
        productData.stock,
        productData.sku,
        productData.imagen_url
      ]
    );
    return rows[0];
  }

  static async update(id, productData) {
    const { rows } = await db.query(
      `UPDATE comercial.producto SET
        nombre = $1, descripcion = $2, precio = $3,
        precio_descuento = $4, id_categoria = $5,
        id_proveedor = $6, stock = $7, sku = $8,
        imagen_url = $9, activo = $10
       WHERE id_producto = $11
       RETURNING *`,
      [
        productData.nombre,
        productData.descripcion,
        productData.precio,
        productData.precio_descuento,
        productData.id_categoria,
        productData.id_proveedor,
        productData.stock,
        productData.sku,
        productData.imagen_url,
        productData.activo,
        id
      ]
    );
    return rows[0];
  }

  static async delete(id) {
    const { rows } = await db.query(
      `UPDATE comercial.producto SET activo = false
       WHERE id_producto = $1
       RETURNING *`,
      [id]
    );
    return rows[0];
  }
}

module.exports = Product;