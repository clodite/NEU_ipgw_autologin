from playwright.sync_api import sync_playwright, Page
import os
import sys
import json
import time

config_file = "data.json"
username = ""
password = ""


def get_resource_path(relative_path):
    """获取资源的绝对路径，兼容开发环境和 PyInstaller 打包后的环境"""
    try:
        # PyInstaller 创建一个临时文件夹并把路径存放在 _MEIPASS 中
        base_path = sys._MEIPASS
    except Exception:
        # 如果是开发环境，使用当前文件所在目录
        base_path = os.path.abspath(".")
    return os.path.join(base_path, relative_path)


def login(page: Page, username: str, password: str) -> Page:
    """执行登录流程，包括点击连接网络和统一身份认证"""
    # ==========================================
    # 点击「连接网络」按钮，捕获弹出的新标签页
    # ==========================================
    first_button_selector = "#login-sso"
    page.wait_for_selector(first_button_selector, state="visible")

    # 监听并捕获新弹出的统一身份认证标签页
    with page.expect_popup() as popup_info:
        page.click(first_button_selector)
    auth_page = popup_info.value
    auth_page.wait_for_load_state("networkidle")
    print("已打开统一身份认证页面")

    # ==========================================
    # 统一身份认证页 - 账号密码输入+点击登录
    # ==========================================
    # 等待账号输入框加载完成
    auth_page.wait_for_selector("#un", state="visible")
    # 输入学号
    auth_page.fill("#un", username)
    # 输入统一身份认证密码
    auth_page.fill("#pd", password)

    # 登录按钮选择器
    login_button_selector = "#index_login_btn"

    auth_page.wait_for_selector(login_button_selector, state="visible")
    auth_page.click(login_button_selector)
    print("已点击登录按钮，正在跳转回网关页面...")

    return auth_page


def printInfo(auth_page: Page):
    """打印用户信息"""
    # ==========================================
    #  等待登录成功，回到原页面爬取5个目标字段
    # ==========================================
    # 等待登录成功后的页面核心元素加载
    auth_page.wait_for_selector("#username", state="visible")
    print("当前已登录，获取用户信息...")

    # 精准匹配5个字段的ID选择器
    user_account = auth_page.inner_text("#username")
    used_flow = auth_page.inner_text("#used-flow")
    used_time = auth_page.inner_text("#used-time")
    account_balance = auth_page.inner_text("#balance")
    ip_address = auth_page.inner_text("#ipv4")

    # 格式化打印结果
    print("=" * 40)
    print(f"用户账号：{user_account}")
    print(f"已用流量：{used_flow}")
    print(f"已用时长：{used_time}")
    print(f"账户余额：{account_balance}")
    print(f"IP 地址：{ip_address}")
    print("=" * 40)
    print("信息获取完成")


def logout(page: Page):
    # ==========================================
    #  执行登出流程
    # ==========================================
    print("正在执行登出操作...")
    # 点击logout按钮
    page.wait_for_selector("#logout", state="visible")
    page.click("#logout")
    print("已点击登出按钮")

    # 点击确认按钮
    page.wait_for_selector("text=确认", state="visible")
    page.click("text=确认")
    print("已确认登出")
    time.sleep(1)


if os.path.exists(config_file):
    try:
        with open(config_file, "r", encoding="utf-8") as f:
            config = json.load(f)
            username = config.get("username", "").strip()
            password = config.get("password", "").strip()
    except Exception as e:
        print(f"读取配置文件失败: {str(e)}")

if not username or not password:
    print("未找到有效账号密码配置，请输入统一身份认证信息")
    # 循环校验账号输入
    while True:
        username_input = input("请输入学号/账号: ").strip()
        if username_input:
            username = username_input
            break
        print("账号不能为空，请重新输入")

    # 循环校验密码输入
    while True:
        password_input = input("请输入密码: ").strip()
        if password_input:
            password = password_input
            break
        print("密码不能为空，请重新输入")

    # 保存配置到json文件
    config_data = {"username": username, "password": password}
    try:
        with open(config_file, "w", encoding="utf-8") as f:
            json.dump(config_data, f, indent=4, ensure_ascii=False)
        print(f"配置已保存到 {os.path.abspath(config_file)}")
    except Exception as e:
        print(f"保存配置文件失败: {str(e)}")


with sync_playwright() as p:
    chromium_path = get_resource_path("chromium/chrome.exe")

    # 1. 启动浏览器
    browser = p.chromium.launch(
        headless=True,
        executable_path=chromium_path,
    )
    # 全局超时时间设置
    page = browser.new_page()
    page.set_default_timeout(30000)

    try:
        # ==========================================
        # 打开IP控制网关初始网址
        # ==========================================
        initial_url = "https://ipgw.neu.edu.cn"
        page.goto(initial_url, wait_until="networkidle")
        print(f"已打开初始网址: {initial_url}")

        # 检测是否存在logout按钮
        auth_page = None
        try:
            page.wait_for_selector("#logout", state="visible", timeout=3000)
            print("检测到已登录状态")
            printInfo(page)
            auth_page = page

            # 询问用户是否登出
            while True:
                user_input = input("是否要登出账号？(y/n): ").strip().lower()
                if user_input in ["y", "n"]:
                    break
                print("请输入 y 或 n")

            if user_input == "y":
                logout(auth_page)
            else:
                print("用户选择不登出，即将关闭浏览器")

        except:
            print("未检测到已登录状态，开始登录流程")
            auth_page = login(page, username, password)
            printInfo(auth_page)

    except Exception as e:
        print(f"脚本执行出错: {str(e)}")
    finally:
        # ==========================================
        # 关闭浏览器
        # ==========================================
        browser.close()
        print("程序已结束")
        input("按任意键退出...")
