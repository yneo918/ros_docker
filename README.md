# ros_docker

ROS 2 Jazzy Jalisco用のDockerワークスペースを用意するリポジトリです。`pkg/`配下に配置したROS 2パッケージをコンテナ内の`/ros2_ws/src`へマウントし、ホストと同じネットワークに接続したままビルド・実行できます。

## リポジトリ構成
- `Dockerfile`: ROS 2 Jazzyベースのイメージを構築します。
- `docker-compose.yml`: ホストネットワークを共有するコンテナ定義です。
- `ros_entrypoint.sh`: ROS 2環境とワークスペースを初期化します。
- `pkg/`: ビルド対象のROS 2パッケージを配置するディレクトリです。

## 事前準備
- DockerとDocker Compose v2プラグインをインストールしておきます。
- Linuxホストでの利用を想定しています（`network_mode: host`はLinux限定機能です）。

## イメージのビルド
ホストユーザーと同じUID/GIDでコンテナユーザーを作成するには次を推奨します。

```bash
docker compose build \
  --build-arg USER_UID=$(id -u) \
  --build-arg USER_GID=$(id -g)
```

## コンテナの起動
`pkg/`配下にパッケージを配置した状態で次を実行します。

```bash
docker compose run --rm ros2
```

コンテナ起動後は`/ros2_ws`がカレントディレクトリになります。`/ros2_ws/src`にはホストの`pkg/`がマウントされています。

## パッケージのビルド
コンテナ内で以下を実行してください。

```bash
colcon build --symlink-install
source install/setup.bash
```

依存パッケージが不足している場合は`rosdep`で解決できます。

```bash
sudo rosdep init 2>/dev/null || true
rosdep update
rosdep install --from-paths src --ignore-src -r -y
```

## 他端末との通信
- `docker-compose.yml`で`network_mode: host`を指定しているため、コンテナはホストと同じネットワークスタックを共有し、ホストが接続しているLAN上の他端末と直接通信できます。
- ROS 2通信相手と同じ`ROS_DOMAIN_ID`を設定してください（既定は0）。必要に応じて`docker-compose.yml`で値を変更できます。
- ファイアウォールでUDPマルチキャスト/ユニキャストが許可されていることを確認してください。
- マルチマシン運用ではDDS実装に`rmw_cyclonedds_cpp`を利用するのが無難です（既定で設定済み）。
- イメージには`ros-jazzy-rmw-cyclonedds-cpp`と`ros-jazzy-xacro`をインストール済みです。
- コンテナ内の`ros`ユーザーは`sudo`をパスワードなしで利用できます。

## よくある操作
- コンテナを終了: `exit` または `Ctrl-D`
- キャッシュを削除して再ビルド: `docker compose build --no-cache`
- 既存コンテナの削除: `docker compose down --remove-orphans`

## トラブルシュート
- ネットワークに出られない場合は、ホストのVPNやファイアウォール設定を確認してください。
- パーミッションエラーが出た場合は、ビルド時にUID/GIDをホストに合わせているか確認してください。
