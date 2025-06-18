// models/Cart.js
const db = require('../config/db');

class Cart {
  static async getActiveCart(customerId) {
    const { rows } = await db.query(
      `SELECT id_carrito FROM comercial.carrito 
       WHERE id_cliente = $1 AND activo = true`,
      [customerId]
    );
    return rows[0]?.id_carrito;
  }

  static async createCart(customerId) {
    const { rows } = await db.query(
      `INSERT INTO comercial.carrito (id_cliente)
       VALUES ($1) RETURNING id_carrito`,
      [customerId]
    );
    return rows[0].id_carrito;
  }

  static async getCartItems(cartId) {
    const { rows } = await db.query(
      `SELECT ci.*, p.nombre, p.imagen_url 
       FROM comercial.carrito_item ci
       JOIN comercial.producto p ON ci.id_producto = p.id_producto
       WHERE ci.id_carrito = $1`,
      [cartId]
    );
    return rows;
  }

  static async addItem(cartId, productId, quantity, price) {
    // Check if item already exists in cart
    const existingItem = await db.query(
      `SELECT id_item FROM comercial.carrito_item 
       WHERE id_carrito = $1 AND id_producto = $2`,
      [cartId, productId]
    );
    
    if (existingItem.rows.length > 0) {
      // Update quantity
      await db.query(
        `UPDATE comercial.carrito_item 
         SET cantidad = cantidad + $1 
         WHERE id_item = $2`,
        [quantity, existingItem.rows[0].id_item]
      );
    } else {
      // Add new item
      await db.query(
        `INSERT INTO comercial.carrito_item (
          id_carrito, id_producto, cantidad, precio_unitario
        ) VALUES ($1, $2, $3, $4)`,
        [cartId, productId, quantity, price]
      );
    }
    
    return this.getCartItems(cartId);
  }

  static async updateItemQuantity(cartId, itemId, quantity) {
    if (quantity <= 0) {
      await this.removeItem(cartId, itemId);
      return this.getCartItems(cartId);
    }
    
    await db.query(
      `UPDATE comercial.carrito_item 
       SET cantidad = $1 
       WHERE id_item = $2 AND id_carrito = $3`,
      [quantity, itemId, cartId]
    );
    
    return this.getCartItems(cartId);
  }

  static async removeItem(cartId, itemId) {
    await db.query(
      `DELETE FROM comercial.carrito_item 
       WHERE id_item = $1 AND id_carrito = $2`,
      [itemId, cartId]
    );
    return this.getCartItems(cartId);
  }

  static async clearCart(cartId) {
    await db.query(
      'DELETE FROM comercial.carrito_item WHERE id_carrito = $1',
      [cartId]
    );
    return [];
  }

  static async deactivateCart(cartId) {
    await db.query(
      'UPDATE comercial.carrito SET activo = false WHERE id_carrito = $1',
      [cartId]
    );
  }
}

module.exports = Cart;