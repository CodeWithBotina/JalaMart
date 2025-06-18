# app/models.py
from flask_login import UserMixin
from app import db, login_manager

class User(UserMixin, db.Model):
    __tablename__ = 'usuario'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128))
    id_cliente = db.Column(db.Integer, db.ForeignKey('cliente.id_cliente'))
    rol = db.Column(db.String(20))
    activo = db.Column(db.Boolean, default=True)
    fecha_creacion = db.Column(db.DateTime)
    ultimo_login = db.Column(db.DateTime)

    def get_id(self):
        return str(self.id)

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))