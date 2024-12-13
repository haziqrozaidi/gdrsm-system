FROM perl:5.38.2

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    lsb-release \
    debconf-utils \
    cpanminus

ADD https://dev.mysql.com/get/mysql-apt-config_0.8.32-1_all.deb .

RUN DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.32-1_all.deb

RUN apt-get update && apt-get install -y \
    libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

COPY cpanfile ./

RUN cpanm --installdeps .

COPY . .

EXPOSE 3000

CMD [ "morbo", "./script/backend" ]
