import tkinter as tk
from tkinter import ttk, messagebox
import psycopg2
from dataclasses import dataclass
from datetime import datetime


@dataclass
class DbConfig:
    host: str = "localhost"
    port: int = 5432
    dbname: str = "gibdd_fines"


class FinesApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Штрафы ГИБДД")
        self.root.geometry("980x640")
        self.conn = None
        self.role = None

        self.config = DbConfig()

        style = ttk.Style()
        try:
            style.theme_use("clam")
        except Exception:
            pass
        base_bg = "#eef2fb"
        primary = "#1f3b73"
        accent = "#2e6ff2"
        hover = "#3b7cff"
        text_dark = "#0f1f3d"
        style.configure("TFrame", background=base_bg)
        style.configure("TLabel", background=base_bg, foreground=text_dark, font=("Segoe UI", 10))
        style.configure("TButton", background=accent, foreground="white", font=("Segoe UI", 10))
        style.map("TButton", background=[("active", hover)], foreground=[("active", "white")])
        style.configure("Treeview", rowheight=24, background="white", fieldbackground="white", bordercolor=primary)
        style.configure("Treeview.Heading", font=("Segoe UI", 10, "bold"), background=primary, foreground="white")

        self.build_login()

    def build_login(self):
        self.login_frame = ttk.Frame(self.root, padding=16)
        self.login_frame.pack(fill="both", expand=True)

        center = ttk.Frame(self.login_frame)
        center.place(relx=0.5, rely=0.5, anchor="center")

        label_font = ("Segoe UI", 11)
        entry_opts = {"width": 32, "font": ("Segoe UI", 11)}

        ttk.Label(center, text="Имя пользователя", font=label_font).grid(row=0, column=0, sticky="w", pady=8, padx=8)
        self.entry_user = ttk.Entry(center, **entry_opts)
        self.entry_user.grid(row=0, column=1, sticky="ew", pady=8, padx=8)

        ttk.Label(center, text="Пароль", font=label_font).grid(row=1, column=0, sticky="w", pady=8, padx=8)
        self.entry_pass = ttk.Entry(center, show="*", **entry_opts)
        self.entry_pass.grid(row=1, column=1, sticky="ew", pady=8, padx=8)

        ttk.Button(center, text="Войти", command=self.handle_login, width=20).grid(row=2, column=0, columnspan=2, pady=14)
        center.columnconfigure(1, weight=1)

    def handle_login(self):
        user = self.entry_user.get().strip()
        password = self.entry_pass.get().strip()
        if not user or not password:
            messagebox.showwarning("Ошибка", "Введите логин и пароль.")
            return
        try:
            self.conn = psycopg2.connect(
                host=self.config.host,
                port=self.config.port,
                dbname=self.config.dbname,
                user=user,
                password=password,
            )
            self.conn.autocommit = True
        except Exception as e:
            messagebox.showerror("Ошибка подключения", str(e))
            return

        self.detect_role()
        if self.role is None:
            messagebox.showerror("Ошибка", "Роль не определена.")
            self.conn.close()
            return

        self.login_frame.destroy()
        self.build_main()

    def detect_role(self):
        try:
            with self.conn.cursor() as cur:
                cur.execute("SELECT pg_has_role(current_user, 'Гражданин', 'member');")
                is_citizen = cur.fetchone()[0]
                cur.execute("SELECT pg_has_role(current_user, 'Инспектор', 'member');")
                is_inspector = cur.fetchone()[0]
        except Exception as e:
            messagebox.showerror("Ошибка", f"Не удалось определить роль: {e}")
            self.role = None
            return

        if is_citizen:
            self.role = "citizen"
        elif is_inspector:
            self.role = "inspector"
        else:
            self.role = None

    def build_main(self):
        self.top_bar = ttk.Frame(self.root, padding=(8, 4))
        self.top_bar.pack(fill="x")
        ttk.Button(self.top_bar, text="Выход", command=self.logout).pack(side="right")

        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill="both", expand=True)

        if self.role == "citizen":
            self.build_citizen_tabs()
        elif self.role == "inspector":
            self.build_inspector_tabs()

    def build_citizen_tabs(self):
        fines_frame = ttk.Frame(self.notebook, padding=8)
        pay_frame = ttk.Frame(self.notebook, padding=8)
        cars_frame = ttk.Frame(self.notebook, padding=8)
        profile_frame = ttk.Frame(self.notebook, padding=8)
        self.notebook.add(fines_frame, text="Мои штрафы")
        self.notebook.add(pay_frame, text="Платежи")
        self.notebook.add(cars_frame, text="Мои авто")
        self.notebook.add(profile_frame, text="Мои данные")

        filter_bar = ttk.Frame(fines_frame)
        filter_bar.pack(fill="x", pady=4)
        ttk.Label(filter_bar, text="Статус:").pack(side="left")
        self.citizen_status = ttk.Combobox(filter_bar, values=["", "ОПЛАЧЕН", "НЕ ОПЛАЧЕН"], width=12)
        self.citizen_status.pack(side="left", padx=4)
        ttk.Label(filter_bar, text="Поиск (место/причина):").pack(side="left")
        self.citizen_search = ttk.Entry(filter_bar, width=24)
        self.citizen_search.pack(side="left", padx=4)
        ttk.Button(filter_bar, text="Обновить", command=self.load_citizen_fines).pack(side="left", padx=4)

        self.fines_tree = ttk.Treeview(
            fines_frame,
            columns=("id", "status", "sum", "dt", "place", "reason", "plate", "car"),
            show="headings",
            height=12,
        )
        for col, title, width in [
            ("id", "Номер", 70),
            ("status", "Статус", 90),
            ("sum", "Сумма", 80),
            ("dt", "Дата/время", 140),
            ("place", "Место", 160),
            ("reason", "Причина", 180),
            ("plate", "Госномер", 90),
            ("car", "Марка/модель", 150),
        ]:
            self.fines_tree.heading(col, text=title)
            self.fines_tree.column(col, width=width, anchor="w", stretch=False)
        self.fines_tree.pack(fill="both", expand=True, pady=6)
        self.fines_tree.tag_configure("even", background="#f5f5f5")

        pay_bar = ttk.Frame(fines_frame)
        pay_bar.pack(fill="x", pady=4)
        ttk.Label(pay_bar, text="Способ оплаты:").pack(side="left")
        self.pay_method = ttk.Entry(pay_bar, width=18)
        self.pay_method.insert(0, "Карта")
        self.pay_method.pack(side="left", padx=4)
        ttk.Button(pay_bar, text="Оплатить выбранный штраф", command=self.make_payment).pack(side="left", padx=4)

        self.pay_tree = ttk.Treeview(
            pay_frame,
            columns=("id", "dt", "sum", "method", "fine"),
            show="headings",
            height=12,
        )
        for col, title, width in [
            ("id", "Номер платежа", 110),
            ("dt", "Дата/время", 140),
            ("sum", "Сумма", 80),
            ("method", "Способ", 120),
            ("fine", "Номер штрафа", 110),
        ]:
            self.pay_tree.heading(col, text=title)
            self.pay_tree.column(col, width=width, anchor="w", stretch=False)
        self.pay_tree.pack(fill="both", expand=True, pady=6)
        self.pay_tree.tag_configure("even", background="#f5f5f5")

        self.cars_tree = ttk.Treeview(
            cars_frame,
            columns=("id", "plate", "brand", "model"),
            show="headings",
            height=12,
        )
        for col, title, width in [
            ("id", "Номер", 70),
            ("plate", "Госномер", 110),
            ("brand", "Марка", 140),
            ("model", "Модель", 160),
        ]:
            self.cars_tree.heading(col, text=title)
            self.cars_tree.column(col, width=width, anchor="w", stretch=False)
        self.cars_tree.pack(fill="both", expand=True, pady=6)
        self.cars_tree.tag_configure("even", background="#f5f5f5")

        
        info_container = ttk.Frame(profile_frame)
        info_container.pack(pady=20, padx=20, anchor="nw")

        ttk.Label(info_container, text="ФИО:").grid(row=0, column=0, sticky="w", pady=4)
        ttk.Label(info_container, text="Адрес регистрации:").grid(row=1, column=0, sticky="w", pady=4)
        ttk.Label(info_container, text="Номер телефона:").grid(row=2, column=0, sticky="w", pady=4)
        ttk.Label(info_container, text="Номер ВУ:").grid(row=3, column=0, sticky="w", pady=4)

        self.lbl_citizen_fio = ttk.Label(info_container, text="")
        self.lbl_citizen_addr = ttk.Label(info_container, text="")
        self.lbl_citizen_phone = ttk.Label(info_container, text="")
        self.lbl_citizen_vu = ttk.Label(info_container, text="")

        self.lbl_citizen_fio.grid(row=0, column=1, sticky="w", pady=4, padx=6)
        self.lbl_citizen_addr.grid(row=1, column=1, sticky="w", pady=4, padx=6)
        self.lbl_citizen_phone.grid(row=2, column=1, sticky="w", pady=4, padx=6)
        self.lbl_citizen_vu.grid(row=3, column=1, sticky="w", pady=4, padx=6)

        self.load_citizen_fines()
        self.load_citizen_payments()
        self.load_citizen_cars()
        self.load_citizen_info()

    def load_citizen_fines(self):
        status = self.citizen_status.get().strip()
        search = self.citizen_search.get().strip()

        status_param = status if status else None
        search_param = search if search else None

        query = """
            SELECT
                id_штрафа,
                статус,
                сумма,
                дата_и_время,
                место_нарушения,
                причина_штрафа,
                госномер,
                (марка || ' ' || модель) AS car
            FROM citizen_fines(%s, %s);
        """
        params = [status_param, search_param]
        self._fill_tree(self.fines_tree, query, params)

    def load_citizen_payments(self):
        query = "SELECT * FROM citizen_payments();"
        self._fill_tree(self.pay_tree, query, [])

    def load_citizen_cars(self):
        query = "SELECT * FROM citizen_cars();"
        self._fill_tree(self.cars_tree, query, [])

    def load_citizen_info(self):
        try:
            with self.conn.cursor() as cur:
                cur.execute("SELECT * FROM citizen_info();")
                row = cur.fetchone()
            if not row:
                self.lbl_citizen_fio.config(text="")
                self.lbl_citizen_addr.config(text="")
                self.lbl_citizen_phone.config(text="")
                self.lbl_citizen_vu.config(text="")
                return

            fio, addr, phone, vu = row
            self.lbl_citizen_fio.config(text=fio or "")
            self.lbl_citizen_addr.config(text=addr or "")
            self.lbl_citizen_phone.config(text=phone or "")
            self.lbl_citizen_vu.config(text=vu or "")
        except Exception as e:
            messagebox.showerror("Ошибка", f"Не удалось загрузить данные о гражданине: {e}")

    def make_payment(self):
        selected = self.fines_tree.selection()
        if not selected:
            messagebox.showwarning("Нет выбора", "Выберите штраф для оплаты.")
            return
        item = self.fines_tree.item(selected[0])["values"]
        fine_id = item[0]
        status = item[1]
        amount = item[2]
        if status == "ОПЛАЧЕН":
            messagebox.showinfo("Оплата", "Штраф уже оплачен.")
            return
        method = self.pay_method.get().strip() or "Карта"
        try:
            with self.conn.cursor() as cur:
                cur.execute("SELECT make_payment(%s, %s, %s);", (fine_id, amount, method))
            messagebox.showinfo("Готово", "Оплата проведена.")
            self.load_citizen_fines()
            self.load_citizen_payments()
        except Exception as e:
            messagebox.showerror("Ошибка оплаты", str(e))

    def build_inspector_tabs(self):
        fines_frame = ttk.Frame(self.notebook, padding=8)
        add_frame = ttk.Frame(self.notebook, padding=8)
        self.notebook.add(fines_frame, text="Штрафы")
        self.notebook.add(add_frame, text="Добавить штраф")

        filter_bar = ttk.Frame(fines_frame)
        filter_bar.pack(fill="x", pady=4)
        ttk.Label(filter_bar, text="Статус:").pack(side="left")
        self.insp_status = ttk.Combobox(filter_bar, values=["", "ОПЛАЧЕН", "НЕ ОПЛАЧЕН"], width=12)
        self.insp_status.pack(side="left", padx=4)
        ttk.Label(filter_bar, text="ФИО:").pack(side="left")
        self.insp_fio = ttk.Entry(filter_bar, width=22)
        self.insp_fio.pack(side="left", padx=4)
        ttk.Label(filter_bar, text="Госномер:").pack(side="left")
        self.insp_plate = ttk.Entry(filter_bar, width=12)
        self.insp_plate.pack(side="left", padx=4)
        ttk.Label(filter_bar, text="Поиск (место/причина):").pack(side="left")
        self.insp_search = ttk.Entry(filter_bar, width=22)
        self.insp_search.pack(side="left", padx=4)
        ttk.Button(filter_bar, text="Поиск", command=lambda: self.load_inspector_fines(require_filter=True)).pack(side="left", padx=4)
        ttk.Button(filter_bar, text="Показать все", command=lambda: self.load_inspector_fines(require_filter=False)).pack(side="left", padx=4)

        self.insp_tree = ttk.Treeview(
            fines_frame,
            columns=("id", "status", "sum", "dt", "place", "reason", "plate", "car", "citizen", "insp"),
            show="headings",
            height=14,
        )
        cols = [
            ("id", "Номер", 70),
            ("citizen", "Гражданин", 150),
            ("status", "Статус", 90),
            ("sum", "Сумма", 80),
            ("reason", "Причина", 140),
            ("dt", "Дата/время", 140),
            ("place", "Место", 140),
            ("plate", "Госномер", 90),
            ("car", "Марка/модель", 140),
            ("insp", "Инспектор", 140),
        ]
        for col, title, width in cols:
            self.insp_tree.heading(col, text=title)
            self.insp_tree.column(col, width=width, anchor="w", stretch=False)
        self.insp_tree.pack(fill="both", expand=True, pady=6)
        self.insp_tree.tag_configure("even", background="#f5f5f5")

        form = ttk.LabelFrame(add_frame, text="Новый штраф", padding=8)
        form.pack(fill="x", pady=6)
        self.var_fio = tk.StringVar()
        self.var_plate = tk.StringVar()
        self.var_sum = tk.StringVar()
        self.var_reason = tk.StringVar()
        self.var_place = tk.StringVar()

        fields = [
            ("ФИО", self.var_fio),
            ("Госномер", self.var_plate),
            ("Сумма", self.var_sum),
            ("Причина", self.var_reason),
            ("Место нарушения", self.var_place),
        ]
        for i, (label, var) in enumerate(fields):
            ttk.Label(form, text=label).grid(row=i, column=0, sticky="w", pady=4, padx=4)
            ttk.Entry(form, textvariable=var, width=30).grid(row=i, column=1, sticky="w", pady=4, padx=4)
        ttk.Button(form, text="Создать штраф", command=self.create_fine).grid(row=len(fields), column=0, columnspan=2, pady=8)

    def load_inspector_fines(self, require_filter=False):
        status = self.insp_status.get().strip()
        fio = self.insp_fio.get().strip()
        plate = self.insp_plate.get().strip()
        search = self.insp_search.get().strip()

        status_param = status if status else None
        fio_param = fio if fio else None
        plate_param = plate if plate else None
        search_param = search if search else None

        if require_filter and not any([status_param, fio_param, plate_param, search_param]):
            messagebox.showinfo("Поиск", "Введите фильтр: статус, ФИО, госномер или строку поиска.")
            return

        query = """
            SELECT
                id_штрафа,
                статус,
                сумма,
                дата_и_время,
                место_нарушения,
                причина_штрафа,
                госномер,
                (марка || ' ' || модель) AS car,
                гражданин_фио,
                инспектор_фио
            FROM inspector_fines(%s, %s, %s, %s);
        """
        params = [status_param, fio_param, plate_param, search_param]
        self._fill_tree(self.insp_tree, query, params)

    def create_fine(self):
        fio = self.var_fio.get().strip()
        plate = self.var_plate.get().strip()
        reason = self.var_reason.get().strip()
        place = self.var_place.get().strip()
        sum_str = self.var_sum.get().strip()

        if not fio or not plate or not sum_str or not reason or not place:
            messagebox.showwarning("Ошибка", "Заполните все поля.")
            return

        try:
            sum_value = float(sum_str)
        except ValueError:
            messagebox.showerror("Ошибка", "Сумма должна быть числом.")
            return

        try:
            with self.conn.cursor() as cur:
                # Используем явное указание типов и схемы для устранения неоднозначности
                cur.execute(
                    """
                    SELECT public.create_fine_by_owner(
                        %s::text, 
                        %s::text, 
                        %s::numeric(10,2), 
                        %s::text, 
                        %s::text
                    );
                    """,
                    (fio, plate, sum_value, reason, place),
                )
            messagebox.showinfo("Готово", "Штраф создан.")
            self.load_inspector_fines(require_filter=False)
        except Exception as e:
            messagebox.showerror("Ошибка", str(e))

    def _fill_tree(self, tree: ttk.Treeview, query: str, params):
        for row in tree.get_children():
            tree.delete(row)
        try:
            with self.conn.cursor() as cur:
                cur.execute(query, params)
                rows = cur.fetchall()
                for idx, r in enumerate(rows):
                    tag = "even" if idx % 2 == 0 else ""
                    tree.insert("", "end", values=r, tags=(tag,))
        except Exception as e:
            messagebox.showerror("Ошибка запроса", str(e))

    def logout(self):
        if self.conn:
            try:
                self.conn.close()
            except Exception:
                pass
            self.conn = None
        self.role = None
        if hasattr(self, "notebook") and self.notebook:
            self.notebook.destroy()
        if hasattr(self, "top_bar") and self.top_bar:
            self.top_bar.destroy()
        if hasattr(self, "login_frame") and self.login_frame:
            self.login_frame.destroy()
        self.build_login()


if __name__ == "__main__":
    root = tk.Tk()
    app = FinesApp(root)
    root.mainloop()

