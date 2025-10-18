FROM kirillsaidov/dlang:ldc2-2.111.0

# update timezone to display correct time
RUN ln -sf /usr/share/zoneinfo/Asia/Almaty /etc/localtime
RUN echo "Asia/Almaty" | tee /etc/timezone

# install system dependencies
RUN apt update && apt upgrade -y && \
    rm -rf /var/lib/apt/lists/*

# set working directory
WORKDIR /app

# copy files
COPY source/ source/
COPY views/ views/
COPY dub.sdl dub.sdl

# fetch dependencies
RUN dub fetch

# build the application
RUN dub build --build=release --compiler=ldc2

# run the application
CMD ["./bin/mywebsite"]



