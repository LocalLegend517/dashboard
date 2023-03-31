FROM node:14-alpine@sha256:434215b487a329c9e867202ff89e704d3a75e554822e07f3e0c0f9e606121b33

RUN mkdir /src
WORKDIR /src

RUN apk update && apk upgrade

COPY package.json /src/
COPY yarn.lock /src/
RUN yarn --pure-lockfile install

COPY . /src
RUN yarn build

EXPOSE 80
ENTRYPOINT ["yarn"]
CMD ["start"]
