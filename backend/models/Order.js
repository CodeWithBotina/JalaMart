// models/Order.js
const db = require('../config/db');

class Order {
  static async getById(id) {
    const { rows } = await db.query(
      'SELECT * FROM comercial.pedido WHERE id_pedido = $1',
      [id]
    );
    return rows[0];
  }

  static async getByCustomer(customerId) {
    const { rows } = await db.query(
      `SELECT * FROM comercial.pedido 
       WHERE id_cliente = $1 
       ORDER BY fecha_pedido DESC`,
      [customerId]
    );
    return rows;
  }

  static async create(orderData) {
    const { rows } = await db.query(
      `INSERT INTO comercial.pedido (
        id_cliente, estado, direccion_envio, 
        metodo_pago, total, subtotal, impuestos
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *`,
      [
        orderData.id_cliente,
        orderData.estado || 'Pendiente',
        orderData.direccion_envio,
        orderData.metodo_pago,
        orderData.total,
        orderData.subtotal,
        orderData.impuestos || 0
      ]
    );
    
    // Add order items
    for (const item of orderData.items) {
      await db.query(
        `INSERT INTO comercial.pedido_item (
          id_pedido, id_producto, cantidad, 
          precio_unitario, descuento
        ) VALUES ($1, $2, $3, $4, $5)`,
        [
          rows[0].id_pedido,
          item.id_producto,
          item.cantidad,
          item.precio_unitario,
          item.descuento || 0
        ]
      );
    }
    
    return rows[0];
  }

  static async getItems(orderId) {
    const { rows } = await db.query(
      `SELECT pi.*, p.nombre, p.imagen_url 
       FROM comercial.pedido_item pi
       JOIN comercial.producto p ON pi.id_producto = p.id_producto
       WHERE pi.id_pedido = $1`,
      [orderId]
    );
    return rows;
  }

  static async updateStatus(orderId, status) {
    const { rows } = await db.query(
      `UPDATE comercial.pedido SET estado = $1
       WHERE id_pedido = $2
       RETURNING *`,
      [status, orderId]
    );
    return rows[0];
  }
}

module.exports = Order;