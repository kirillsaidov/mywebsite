FROM kirillsaidov/dmd:2.111.0

# Set work directory
WORKDIR /app

# Copy project
COPY . .

# Build project
# TODO: here does not work
# RUN dub build --build=release

# Run the app
CMD ["./bin/mywebsite"]


