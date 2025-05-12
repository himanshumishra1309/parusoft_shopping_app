import dotenv from 'dotenv';
import { app } from './app.js';
import connectDB from './db/index.js';

dotenv.config({path: './.env'});

connectDB().then(() => {
    const PORT = process.env.PORT || 8005;
    app.listen(PORT, "0.0.0.0", () => {
        console.log(`Server is running on port ${PORT}`);
    });

    app.on("error", (error) => {
      console.log("Error :", error);
      throw error;
    });
}).catch((error) => {
    console.error('Failed to connect to the database:', error);
    process.exit(1);
});