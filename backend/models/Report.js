// models/Report.js
const db = require('../config/db');

class Report {
  static async getBestSellingProducts(limit = 10) {
    const { rows } = await db.query(
      'SELECT * FROM reportes.productos_mas_vendidos LIMIT $1',
      [limit]
    );
    return rows;
  }

  static async getBestOffers() {
    const { rows } = await db.query(
      'SELECT * FROM reportes.mejores_ofertas'
    );
    return rows;
  }

  static async getMostActiveCustomers(limit = 5) {
    const { rows } = await db.query(
      'SELECT * FROM reportes.clientes_mas_activos LIMIT $1',
      [limit]
    );
    return rows;
  }

  static async getSalesByCategory() {
    const { rows } = await db.query(
      'SELECT * FROM reportes.ventas_por_categoria'
    );
    return rows;
  }

  static async getProductsByCategory() {
    const { rows } = await db.query(
      'SELECT * FROM reportes.productos_por_categoria'
    );
    return rows;
  }
}

module.exports = Report;