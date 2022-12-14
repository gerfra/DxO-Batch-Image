""" -----------------------------------------------------------------------------------------------------------
This program was written for non-commercial purposes, it is intended for educational purposes only.
It is not intended to support piracy, it can be used together with the regularly purchased DxO Photolab program,
all rights belong to the rightful owners. I do not answer any questions that violate copyright.
Use DxO-Batch-Image at your own risk.
The program originated from a question in the official DxO forum
"is there a CLI to use the program to process large amounts of images without going through the GUI?",
it was revealed in the forum that there is a CLI,  but not finding anything usable I decided to write
something for myself, which I decided to share with everyone.
 Program:					DxO-Batch-Image
 Python Version: 			3.10.8
 Author:         			Nextechnics
 WebSite:		 			https://www.nextechnics.com
 GitHub:		 			https://github.com/gerfra
 Usage: 		 			This program is used to process images massively, using specific preset profile,
                            without using the user interface of the DxO Photolab program
 License DxO-Batch-Image: 	GPL3 https://www.gnu.org/licenses/gpl-3.0.html
----------------------------------------------------------------------------------------------------------- """

import os
import re
from pathlib import Path
import platform
import subprocess
import shutil
import time
import xml.etree.ElementTree as ET
import webbrowser
import configparser
# ------------------
import tkinter as tk
import tkinter.font as tkFont
import tkinter.scrolledtext as st
from tkinter import messagebox
# ------------------
from tkinter import ttk
from tkinter import IntVar
from tkinter import filedialog

default_output = os.path.join(os.getcwd(), "Output")
if not os.path.exists(default_output):
    os.mkdir(default_output)
process = None
loop = 0  # Kill Process and loop
app_data_local = os.getenv('LOCALAPPDATA')  # windows
prog_file = os.getenv('ProgramFiles')  # windows
dxo_path = []


# extra... config file not implemented
def configuration(cfg):
    config = configparser.ConfigParser()
    data = {
        "PATH": {
            'ProcessingCore': '',
            'Modules': '',
            'Presets': '',
            'UserCfg': '',
            'CAFList6': '',
            'Ocl64': ''
        }
    }
    config.read_dict(data)
    data['PATH'].update(cfg)
    config.read_dict(data)
    with open("dxo_cli.conf", "w") as fp:
        config.write(fp)


def find_path_windows(data_local, exe_folder, text_area, cbpreset):
    try:
        messagebox.showinfo("       INITIALIZE DXO CLI        ", "            WAIT            ")
        dxo_path2 = {'ProcessingCore': "", 'Modules': "", 'Presets': "", 'UserCfg': "", 'CAFList6': "", 'Ocl64': ""}
        global dxo_path
        # find executable
        for exe_folder, dirs, files in os.walk(exe_folder):
            target2 = os.path.basename(os.path.normpath(exe_folder))
            if target2.startswith("DxO"):
                for file in files:
                    if file.endswith("Core.exe") or file.endswith("core.exe"):
                        dxo_path.append(os.path.join(exe_folder, file))
                        dxo_path2.update({'ProcessingCore': os.path.join(exe_folder, file)})
        # find attribute
        for data_local, dirs, files in os.walk(data_local):
            target = os.path.basename(os.path.normpath(data_local))
            if target.startswith("DxO"):
                for dire in dirs:
                    if dire.endswith("Modules"):
                        dxo_path.append(os.path.join(data_local, dire))
                        dxo_path2.update({'Modules': os.path.join(data_local, dire)})
                    if dire.endswith("Presets"):
                        dxo_path.append(os.path.join(data_local, dire))
                        dxo_path2.update({'Presets': os.path.join(data_local, dire)})
                    if dire.startswith("DxO.PhotoLab"):
                        cfg_file = os.path.join(data_local, dire)
                        for cfg_file, dirs2, files2 in os.walk(cfg_file):
                            for file2 in files2:
                                if file2 == "user.config":
                                    dxo_path.append(os.path.join(cfg_file, file2))
                                    dxo_path2.update({'Presets': os.path.join(cfg_file, file2)})

                for file in files:
                    if file == "CAFList6.db":
                        dxo_path.append(os.path.join(data_local, file))
                        dxo_path2.update({'CAFList6': os.path.join(data_local, file)})
                    if file == "ocl64.cache":
                        dxo_path.append(os.path.join(data_local, file))
                        dxo_path2.update({'Ocl64': os.path.join(data_local, file)})

        # print(dxo_path[0], "\n", dxo_path[1], "\n", dxo_path[2], "\n", dxo_path[3], "\n", dxo_path[4], "\n", dxo_path[5])
        text_area.configure(state='normal')
        text_area.insert(tk.END, " DXO CONFIGURED!!! \n")
        text_area.update()
        text_area.configure(state='disabled')

        dxo_preset(dxo_path[3], cbpreset)  # initialize combobox

        shutil.copy2(dxo_path[1], os.getcwd())

        exist_file = os.path.isfile("user.config")
        if exist_file:
            extract_xml()
            dxo_path2.update({'UserCfg': extract_xml()})
            configuration(dxo_path2)
        else:
            messagebox.showinfo("Error user.config Not Found", "CLOSE")

        return dxo_path
    except Exception as e:

        messagebox.showinfo("Error", str(e) + "             Attention             ")

        exit()


def find_path_macos(data_local, exe_folder, text_area, cbpreset):
    try:
        print("not implemented")
    except Exception as e:

        messagebox.showinfo("Error", str(e) + "             Attention             ")

        exit()


def extract_xml():
    tree = ET.parse('user.config')
    xml_root = tree.getroot()

    filexml = "config.xml"
    with open(filexml, "w") as f:
        for elem in xml_root.findall('./userSettings/DxO.PhotoLab.Properties.Settings/setting'):
            if elem.attrib['name'] == "OutputSettings":
                for subelem in elem:
                    f.write(subelem.text)
    filexml = os.path.join(os.getcwd(), filexml)

    return filexml


def output_dopcor(text_area, preset, suffix, core, api, debug, output):
    if debug == 0:
        debug = "--debug"
    else:
        debug = ""

    folder = filedialog.askdirectory(initialdir=os.getcwd(), title="Select OutPut Folder")
    if folder == "":
        messagebox.showinfo("SELECT IMAGES FOLDER", "CLOSE")
        return
    folder = str(Path(folder))

    file_to_edit = []

    ext_target = "jpg|3fr|ari|arw|bay|braw|crw|cr2|cr3|cap|data|dcs|dcr|dng|drf|eip|erf|fff|gpr|iiq|k25|kdc|mdc|mef|mos" \
                 "|mrw|nef|nrw|obm|orf|pef|ptx|pxn|r3d|raf|raw|rwl|rw2|rwz|sr2|srf|srw|tif|x3f "
    pat = re.compile(r'[.](' + ext_target + ')$', re.IGNORECASE)
    for filename in os.listdir(folder):
        if re.search(pat, filename):
            file_to_edit.append(os.path.join(folder, filename))

    xmlfile = os.path.join(os.getcwd(), "config.xml")

    try:
        # -c = Modules
        # -d = CAFList6.db
        # -k = ocl64.cache
        # -i = Input folder
        # -s = Name preset
        # -o = config.xml
        # -p = "Output"
        # -f = "_dxo"
        # -t = Threads
        # --opencl
        # --debug

        global process
        global loop
        #print("stauts----", process, "loop----", loop)

        for job in file_to_edit:

            cmd = r'"' + dxo_path[0] + '" ' \
               r'-c="' + dxo_path[2] + '" ' \
               r'-d="' + dxo_path[4] + '" ' \
               r'-k="' + dxo_path[5] + '" ' \
               r'-i="' + job + '" ' \
               r'-s="' + preset + '" ' \
               r'-o="' + xmlfile + '" ' \
               r'-p="' + output + '" ' \
               r'-f="' + suffix + '" ' \
               r'-t=' + core + ' ' \
               r'' + api + ' ' \
               r'' + debug + '"'

            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=False,
                                       encoding='utf-8',
                                       errors='replace')

            if loop >= 1:
                process.kill()
                messagebox.showinfo("PROCESS TERMINATED",
                                    "             PID:-------" + str(process.pid) + "             ")
                break

            while process:
                time.sleep(0.05)
                realtime_output = process.stdout.readline()

                if realtime_output == '' and process.poll() is not None:
                    break

                if realtime_output:
                    #print(realtime_output.strip(), flush=True)
                    text_area.configure(state='normal')
                    text_area.insert(tk.END, realtime_output.strip() + "\n")
                    text_area.update()
                    text_area.configure(state='disabled')

            process.kill()

        process = None
        messagebox.showinfo("PROCESS TERMINATED", "             FINISH             ")

    except Exception as e:

        messagebox.showinfo("Error", str(e) + "             Attention             ")

        exit()

    loop = 0


def process_kill():
    global loop

    if process is not None:
        loop = 1
        process.kill()


def dxo_preset(preset, cb_preset):

    list_preset = []

    for roots, dirs, files in os.walk(preset):
        for file in files:
            if file.endswith(".preset"):
                list_preset.append(os.path.join(roots, file))

    cb_preset['values'] = list_preset

    return list_preset


def buy_beer():
    myurl = "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=francescogerratana%40gmail%2ecom&lc=US" \
            "&item_name=Francesco%20Gerratana&item_number=Buy%20me%20a%20Beer%2c%20Offrimi%20una%20Birra%2e&no_note=0" \
            "&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHostedGuest "

    webbrowser.open(myurl, new=2)


def open_folder():
    global default_output
    folder = filedialog.askdirectory(initialdir=default_output, title="Select OutPut Folder")
    if folder == "":
        folder = default_output
    default_output = str(Path(folder))
    #print(default_output)
    return default_output


class App:
    def __init__(self, _root):
        # setting title
        root.title("DXO CLI | DXO BATCH PROCESSING")
        icon = os.path.join(os.getcwd(), r"res\icons.ico")
        root.iconbitmap(root, default=icon)  # configure icon in normal spot
        # setting window size
        width = 600
        height = 500
        screenwidth = root.winfo_screenwidth()
        screenheight = root.winfo_screenheight()
        align_center = '%dx%d+%d+%d' % (width, height, (screenwidth - width) / 2, (screenheight - height) / 2)
        root.geometry(align_center)
        root.resizable(width=True, height=True)
        root["bg"] = "#6666CD"
        root.attributes('-topmost', True)

        def clicked():
            output_dopcor(text_area, preset_val.get(), g_line_edit_412.get(), core_cb.get(), core_api.get(), cb.get(),
                          default_output)

        g_button_162 = tk.Button(root)
        g_button_162["bg"] = "#e9e9ed"
        ft = tkFont.Font(family='Times', size=10)
        g_button_162["font"] = ft
        g_button_162["fg"] = "#000000"
        g_button_162["justify"] = "center"
        g_button_162["text"] = "START_PROCESS"
        g_button_162.place(x=20, y=460, width=170, height=25)
        g_button_162["command"] = clicked

        g_button_169 = tk.Button(root)
        g_button_169["bg"] = "#e9e9ed"
        ft = tkFont.Font(family='Times', size=10)
        g_button_169["font"] = ft
        g_button_169["fg"] = "#000000"
        g_button_169["justify"] = "center"
        g_button_169["text"] = "KILL_PROCESS"
        g_button_169.place(x=210, y=460, width=170, height=25)
        g_button_169["command"] = process_kill

        g_button_537 = tk.Button(root)
        g_button_537["bg"] = "gold"
        g_button_537["activebackground"] = "gold3"
        ft = tkFont.Font(family='Times', size=10)
        g_button_537["font"] = ft
        g_button_537["fg"] = "#000000"
        g_button_537["justify"] = "center"
        g_button_537["text"] = "Buy Me A Coffee"
        g_button_537.place(x=400, y=460, width=170, height=25)
        g_button_537["command"] = buy_beer

        cb = IntVar()
        g_check_box_674 = tk.Checkbutton(root)
        ft = tkFont.Font(family='Times', size=10)
        g_check_box_674["font"] = ft
        g_check_box_674["fg"] = "#000000"
        g_check_box_674["bg"] = "#6666CD"
        g_check_box_674["justify"] = "center"
        g_check_box_674["text"] = "debug"
        g_check_box_674["activebackground"] = "#6666CD"
        g_check_box_674.place(x=390, y=40, width=70, height=25)
        g_check_box_674["offvalue"] = "1"
        g_check_box_674["onvalue"] = "0"  # 1 = off; 0 = on
        g_check_box_674["variable"] = cb

        cb2 = IntVar(value=1)
        g_check_box_48 = tk.Checkbutton(root)
        ft = tkFont.Font(family='Times', size=10)
        g_check_box_48["font"] = ft
        g_check_box_48["fg"] = "#000000"
        g_check_box_48["bg"] = "#6666CD"
        g_check_box_48["justify"] = "center"
        g_check_box_48["text"] = "listening"
        g_check_box_48["activebackground"] = "red"
        g_check_box_48["activeforeground"] = "white"
        g_check_box_48["disabledforeground"] = "#000000"
        g_check_box_48["selectcolor"] = "red"
        g_check_box_48["state"] = "disabled"
        g_check_box_48.place(x=500, y=40, width=70, height=25)
        g_check_box_48["offvalue"] = "1"
        g_check_box_48["onvalue"] = "0"
        g_check_box_48["variable"] = cb2

        g_button_24 = tk.Button(root)
        g_button_24["bg"] = "#e9e9ed"
        ft = tkFont.Font(family='Times', size=10)
        g_button_24["font"] = ft
        g_button_24["fg"] = "#000000"
        g_button_24["justify"] = "center"
        g_button_24["text"] = "OUTPUT"
        g_button_24.place(x=280, y=40, width=100, height=25)
        g_button_24["command"] = open_folder

        # create a combobox
        selected_month = tk.StringVar()

        preset_val = ttk.Combobox(root, textvariable=selected_month)

        preset_val['values'] = []

        preset_val['state'] = 'readonly'

        # place the widget
        preset_val.pack(fill=tk.X, padx=5, pady=5)

        # create a combobox
        cores = ["1", "2", "3", "4"]  # options
        core_cb = ttk.Combobox(root, values=cores, width=7)  # Combobox
        core_cb.set('1')  # default selected option

        # prevent typing a value
        core_cb['state'] = 'readonly'

        # place the widget
        core_cb.place(x=120, y=40, width=70, height=25)

        # create a combobox
        core_api = ["--opencl", "--cl"]
        core_api = ttk.Combobox(root, values=core_api)
        core_api.set("--opencl")

        # prevent typing a value
        core_api['state'] = 'readonly'

        # place the widget
        core_api.place(x=200, y=40, width=70, height=25)

        # scrool
        text_area = st.ScrolledText(root, width=30, height=8, font=("Times New Roman", 10))
        text_area.place(x=5, y=90, width=590, height=350)

        # input text
        uno = tk.StringVar(value="_dxo")
        g_line_edit_412 = tk.Entry(root, textvariable=uno)
        g_line_edit_412["borderwidth"] = "1px"
        ft = tkFont.Font(family='Times', size=10)
        g_line_edit_412["font"] = ft
        g_line_edit_412["fg"] = "#000000"
        g_line_edit_412["justify"] = "center"
        g_line_edit_412["text"] = "Entry"
        g_line_edit_412.place(x=10, y=40, width=100, height=25)

        system = platform.system().lower()
        if system == "windows":
            find_path_windows(app_data_local, prog_file, text_area, preset_val)
        elif system == "darwin":  # Not implemented
            find_path_macos(app_data_local, prog_file, text_area, preset_val)


if __name__ == "__main__":
    root = tk.Tk()
    app = App(root)
    root.mainloop()
