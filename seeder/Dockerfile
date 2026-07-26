FROM postgres:16-alpine

# Install redis-cli + bash
RUN apk add --no-cache redis bash curl

# Copy all templates into the image
COPY templates/ /templates/

# Copy the seed script
COPY seeder/seed.sh /seed.sh
RUN chmod +x /seed.sh

ENTRYPOINT ["/seed.sh"]
