"""
[改善点]
・zoom機能
・ラベルの消去機能
・escを押したら、そこまででannotationのfor文をbreakしてcsvファイルを出力する処理に移るようにする
[注意点]
annotationとdragは一緒にできないので注意(annotationした後にdragはできる)
"""

import os
import csv
import tkinter as tk
from tkinter import filedialog
from PIL import Image, ImageTk, ImageDraw, ImageFont

class AnnotationTool:
    def __init__(self, master, folder_path, file_name, labels):
        # windowオブジェクトの格納とタイトル付け
        self.master = master
        self.master.title("Annotation Tool")
        self.folder_path = folder_path
        self.file_name = file_name
        self.image_path = os.path.join(self.folder_path, self.file_name)
        self.labels = labels

        # 座標データを保存する辞書の作成
        self.points = {}

        # annotationのために必要なidxの準備
        self.current_label_idx = 0
        self.current_point = None
        self.current_item = None

        # 色のリスト
        self.colors = ["red", "blue", "green", "yellow", "purple", "orange", "pink", "cyan", "magenta", "brown"]

        # 画像の読み込みと判例の追加と表示
        self.image = Image.open(self.image_path)
        self.annotate_legend()
        self.photo = ImageTk.PhotoImage(self.image, master=self.master)
        self.canvas = tk.Canvas(self.master, width=self.image.width, height=self.image.height)
        self.canvas.pack()
        self.canvas.create_image(0, 0, anchor=tk.NW, image=self.photo)

        # マウスイベントの設定
        self.canvas.bind("<Button-1>", self.on_click)
        self.canvas.bind("<B1-Motion>", self.on_drag)
        self.canvas.bind("<ButtonRelease-1>", self.on_release) #マウス離した時
        self.master.bind("<Return>", self.close_window)

    # アノテーションの設定
    def annotate_legend(self):
        # フォント、凡例の描画のスタート位置の設定
        draw = ImageDraw.Draw(self.image)
        font = ImageFont.load_default(size=15)
        legend_margin = 10
        legend_x = self.image.width - legend_margin - 60
        legend_y = legend_margin  

        # 凡例の大きさとか間隔とかの設定
        side_length = 15
        margin_each_legend = 10

        # ラベルごとに色と名前を描画
        for idx, label in enumerate(self.labels):
            color = self.colors[idx % len(self.colors)]
            # 色のサンプルの設定(labelの色の四角形をいい感じの位置に配置)
            draw.rectangle(
                [(legend_x, legend_y + idx * (side_length + margin_each_legend)), 
                (legend_x + side_length, legend_y + side_length + idx * (side_length + margin_each_legend))], 
                fill=color)
            # ラベル名を描画(rect angleの右側に)
            draw.text((legend_x + (side_length + 5), legend_y + idx * (side_length+margin_each_legend)), label, fill="white", font=font)


    # コールバック関数の設定
    def on_click(self, event):
        # クリックした点のobjectを返す(annotationしたobjectを選んだ場合は、このobjectには'current'タグ以外のタグが付いている)
        clicked_item = self.canvas.find_closest(event.x, event.y)
        if clicked_item:
            tags = self.canvas.gettags(clicked_item)
            # tags[0]が自分で登録したタグだった時(clicked_itemが既にannotation済みのラベルだった場合)
            # drag操作のためにself.current_item, self.current_pointを登録して関数をreturnする
            if tags and tags[0].startswith("point_"):
                self.current_item = clicked_item
                self.current_point = tags[0]
                return

        if self.current_label_idx < len(self.labels):
            # label_idxに該当するラベルをlabelsから取得し、座標値を辞書に格納
            label = self.labels[self.current_label_idx]
            x, y = event.x, event.y
            color = self.colors[self.current_label_idx % len(self.colors)]
            self.points[label] = (x, y)

            # タグの設定(自分で作ったタグをcreate_oval時にそのitemのタグのリストの先頭に追加する。('current'タグはデフォルトで入っている))
            point_tag = f"point_{label}"
            self.canvas.create_oval(x-5, y-5, x+5, y+5, fill=color, tags=(point_tag,))

            self.current_label_idx += 1
        else:
            print("All points have been annotated.")

    def on_drag(self, event):
        # self.current_pointとself.current_itemが登録されている時(既にアノテーションされた点がドラッグされた時)
        if self.current_point and self.current_item:
            x, y = event.x, event.y
            # itemオブジェクトの座標を変更
            self.canvas.coords(self.current_item, x-5, y-5, x+5, y+5)
            _, label = self.current_point.split("_")
            self.points[label] = (x, y)

    def on_release(self, event):
        # on_drag操作で使用する変数の中身を空にする
        self.current_point = None
        self.current_item = None

    def close_window(self, event):
        # 注釈を描画する新しい画像データを作成
        annotated_image = self.image.copy()

        # 注釈を描画
        draw = ImageDraw.Draw(annotated_image)
        self.annotate_legend()
        for label, coordination in self.points.items():
            color = self.colors[self.labels.index(label) % len(self.colors)]
            x, y = coordination
            draw.ellipse([(x-5, y-5), (x+5, y+5)], fill=color)

        # 現在の画像を所定のディレクトリにpngファイルとして保存する
        save_fold_path = os.path.join(self.folder_path, 'labeled_figures')
        if not os.path.exists(save_fold_path):
            os.makedirs(save_fold_path)
        file_name_elements = self.file_name.split('.')
        annotated_file_name = ''.join([file_name_elements[0], '(annotated)'])
        annotated_file_name = '.'.join([annotated_file_name, file_name_elements[1]])
        save_figure_path = os.path.join(save_fold_path, annotated_file_name)
        annotated_image.save(save_figure_path)

        # windowオブジェクトを閉じる
        self.master.destroy()

    # 外部から使用するメソッド. 座標値を取得
    def get_coordination(self):
        return self.points

def main():
    # pathの設定
    pwd = os.getcwd()
    manual_image_path = os.path.join(pwd, 'save_figure', 'specific_images')
    print('アノテーションしたい画像の入ったフォルダを選択してください')
    dialog_window = tk.Tk()
    dialog_window.withdraw()
    selected_folder = filedialog.askdirectory(initialdir=manual_image_path)
    dialog_window.destroy()

    candidate_files = os.listdir(selected_folder)
    annotate_image_files = [file for file in candidate_files if file.startswith('trial') and file.endswith('.png')]
    annnotate_image_num = len(annotate_image_files)

    # ラベル設定
    labels = [] 
    while True:
        label = input("ポイントのラベル名を入力してください(これ以上必要ない場合はendと入力してください):")
        if label == "end":
            break
        else:
            labels.append(label)

    # csvファイルの作成に使用するlistの作成
    marker_coordination_lists = []
    for image_idx in range(annnotate_image_num):
        # 表示するimageのfile名の取得
        ref_image_file_name = annotate_image_files[image_idx]

        # window_obj
        window_obj = tk.Tk()
        app = AnnotationTool(window_obj, selected_folder, ref_image_file_name, labels)

        # window objectが閉じられるまでここで処理を停止
        window_obj.mainloop()
        
        # アノテーションの画像座標を辞書で取得
        coordination_dict = app.get_coordination()
        marker_coordination_lists.append(coordination_dict)

    # csvファイルへの書き込み
    selected_folder_elements = selected_folder.split('/')
    date_folder_name = selected_folder_elements[-1]

    # ファイルのセーブ場所の設定
    if 'auto' in selected_folder_elements:
        diff_contents = selected_folder_elements[-2]
        csv_file_save_fold = os.path.join(pwd, 'save_data', 'auto', 'coordination_data', diff_contents, date_folder_name)
    else:
        csv_file_save_fold = os.path.join(pwd, 'save_data', 'manual', 'coordination_data', date_folder_name)
    
    if not os.path.exists(csv_file_save_fold):
        os.makedirs(csv_file_save_fold)

    csv_file_name = 'coordination_data_list.csv'
    csv_file_save_path = os.path.join(csv_file_save_fold, csv_file_name)
    with open(csv_file_save_path, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)

        # 列名を書き込み
        column_names = []
        for key, value in marker_coordination_lists[0].items():
            column_names.append(f'{key}_x')
            column_names.append(f'{key}_y')
        writer.writerow(column_names)

        # リストをループして、各行に4つのラベルの画像座標を書き込み
        for marker_coordination_list in marker_coordination_lists:
            row = []
            for key, value in marker_coordination_list.items():
                row.append(value[0])
                row.append(value[1])
            writer.writerow(row)
    csvfile.close()

if __name__ == "__main__":
    main()
