# syntax=docker/dockerfile:1
FROM node:20-slim

WORKDIR /app

# Copy package.json for layer caching
COPY package.json ./
RUN npm install

# Copy the rest of the application
COPY . .

EXPOSE 5173

CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
