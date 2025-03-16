FROM node:18-alpine
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install

COPY . .

ENV PORT=5002
ENV MONGO_URI=mongodb+srv://manjyotsinghchaudhary:Xs7AnsL6bDfhirvy@travelbackend.qyczv.mongodb.net/profile_db

EXPOSE 5002

CMD ["node", "index.js"]
