// server.js
const express = require('express');
const bodyParser = require('body-parser');
const bcrypt = require('bcrypt');
const cors = require('cors');
const db = require('./bd_conf'); // Importa la configuración de la BD


const app = express();
const port = process.env.PORT || 3000; // Puerto para el servidor backend

// Middlewares
app.use(cors()); // Habilita CORS para todas las rutas
app.use(bodyParser.json()); // Para parsear cuerpos de solicitud JSON
app.use(bodyParser.urlencoded({ extended: true })); // Para parsear cuerpos x-www-form-urlencoded

// Endpoint para registrar usuarios
app.post('/api/usuarios/registrar', async (req, res) => {
  const { nombre_usuario, correo_electronico, contrasena, rol } = req.body;

  // Validación básica (puedes expandirla mucho más)
  if (!nombre_usuario || !correo_electronico || !contrasena || !rol) {
    return res.status(400).json({ message: 'Todos los campos son obligatorios.' });
  }

  if (contrasena.length < 6) {
    return res.status(400).json({ message: 'La contraseña debe tener al menos 6 caracteres.' });
  }

  try {
    // 1. Hashear la contraseña
    const saltRounds = 10; // Costo del hashing
    const contrasena_hash = await bcrypt.hash(contrasena, saltRounds);

    // 2. Preparar la consulta SQL
    // Los campos id_usuario (si es SERIAL), fecha_creacion, fecha_actualizacion
    // y activo pueden ser manejados por la BD directamente.
    // Asumimos que 'activo' tiene un valor por defecto TRUE o lo establecemos aquí.
    const queryText = `
      INSERT INTO usuarios (nombre_usuario, correo_electronico, contrasena_hash, rol, activo, fecha_creacion, fecha_actualizacion)
      VALUES ($1, $2, $3, $4, TRUE, NOW(), NOW())
      RETURNING id_usuario, nombre_usuario, correo_electronico, rol, activo, fecha_creacion;
    `;
    // NOW() es una función de PostgreSQL para la fecha y hora actual.
    // TRUE para el campo 'activo'.

    const values = [nombre_usuario, correo_electronico, contrasena_hash, rol];

    // 3. Ejecutar la consulta
    const result = await db.query(queryText, values);
    const nuevoUsuario = result.rows[0];

    console.log('Usuario registrado:', nuevoUsuario);
    res.status(201).json({
      message: 'Usuario registrado exitosamente.',
      usuario: nuevoUsuario
    });

  } catch (error) {
    console.error('Error al registrar usuario:', error);
    // Manejar errores específicos, por ejemplo, correo duplicado (error.code === '23505')
    if (error.code === '23505' && error.constraint === 'usuarios_correo_electronico_key') { // Asumiendo que tienes una constraint unique en correo_electronico
      return res.status(409).json({ message: 'El correo electrónico ya está registrado.' });
    }
    res.status(500).json({ message: 'Error interno del servidor al registrar el usuario.' });
  }
});

// Endpoint para login
app.post('/api/usuarios/login', async (req, res) => {
  const { correo_electronico, contrasena } = req.body;

  if (!correo_electronico || !contrasena) {
    return res.status(400).json({ message: 'Correo y contraseña son obligatorios.' });
  }

  try {
    // Buscar al usuario por correo
    const query = `SELECT * FROM usuarios WHERE correo_electronico = $1 AND activo = TRUE`;
    const result = await db.query(query, [correo_electronico]);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Usuario no encontrado o inactivo.' });
    }

    const usuario = result.rows[0];

    // Comparar contraseñas
    const contrasenaValida = await bcrypt.compare(contrasena, usuario.contrasena_hash);
    if (!contrasenaValida) {
      return res.status(401).json({ message: 'Contraseña incorrecta.' });
    }

    // Retornar datos relevantes (sin contraseña)
    res.status(200).json({
      message: 'Login exitoso.',
      usuario: {
        id_usuario: usuario.id_usuario,
        nombre_usuario: usuario.nombre_usuario,
        correo_electronico: usuario.correo_electronico,
        rol: usuario.rol
      }
    });

  } catch (error) {
    console.error('Error en login:', error);
    res.status(500).json({ message: 'Error interno del servidor en login.' });
  }
});


// Ruta de prueba
app.get('/', (req, res) => {
  res.send('API de Registro de Usuarios funcionando!');
});

app.listen(port, () => {
  console.log(`Servidor backend corriendo en http://localhost:${port}`);
});