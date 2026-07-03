import os
import time
import schedule
from datetime import datetime, timedelta
from pytz import timezone
from sqlalchemy import create_engine, func
from sqlalchemy.orm import sessionmaker
import google.generativeai as genai
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
from database.database import SessionLocal
from schemas import models
from dotenv import load_dotenv

# Configure Gemini API

load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
genai.configure(api_key=GEMINI_API_KEY)


REPORTS_DIR = 'reports'
os.makedirs(REPORTS_DIR, exist_ok=True)

db = SessionLocal()

def fetch_daily_alerts(session, target_date):
    """
    Fetch all alerts for a specific day from the database.
    Adjust the model import and query based on your schema.
    """
    
    start_of_day = datetime.combine(target_date, datetime.min.time())
    end_of_day = datetime.combine(target_date, datetime.max.time())
    
    alerts = session.query(models.Alert).filter(
        models.Alert.created_at >= start_of_day,
        models.Alert.created_at <= end_of_day
    ).order_by(models.Alert.created_at.asc()).all()
    
    return alerts

def get_alert_statistics(alerts):
    """
    Calculate statistics from alerts.
    """
    total_alerts = len(alerts)
    
    # Count by severity/priority (using 'level' field)
    severity_counts = {}
    device_counts = {}
    sensor_counts = {}
    
    for alert in alerts:
        # Severity - use 'level' field
        level = getattr(alert, 'level', 'unknown')
        if level:
            # Normalize the level name
            level_str = str(level).lower()
            severity_counts[level_str] = severity_counts.get(level_str, 0) + 1
        else:
            severity_counts['unknown'] = severity_counts.get('unknown', 0) + 1
        
        # Device
        device_id = getattr(alert, 'device_id', 'unknown')
        if device_id:
            device_counts[device_id] = device_counts.get(device_id, 0) + 1
        
        # Sensor
        sensor_id = getattr(alert, 'sensor_id', 'unknown')
        if sensor_id:
            sensor_counts[sensor_id] = sensor_counts.get(sensor_id, 0) + 1
    
    return {
        'total': total_alerts,
        'by_severity': severity_counts,
        'by_device': device_counts,
        'by_sensor': sensor_counts
    }

def format_alerts_for_gemini(alerts, stats, target_date):
    """
    Format alerts data into a prompt for Gemini API.
    """
    date_str = target_date.strftime("%Y-%m-%d")
    
    prompt = f"""You are an industrial monitoring system analyst. Generate a comprehensive daily report for {date_str}.

**Statistics:**
- Total Alerts: {stats['total']}
- Alerts by Level: {stats['by_severity']}
- Most Active Device: {max(stats['by_device'].items(), key=lambda x: x[1])[0] if stats['by_device'] else 'None'} ({max(stats['by_device'].values()) if stats['by_device'] else 0} alerts)
- Most Active Sensor: {max(stats['by_sensor'].items(), key=lambda x: x[1])[0] if stats['by_sensor'] else 'None'} ({max(stats['by_sensor'].values()) if stats['by_sensor'] else 0} alerts)

**Alerts Detail:**
"""
    
    for i, alert in enumerate(alerts[:50], 1):  # Limit to 50 alerts to avoid token limits
        alert_time = getattr(alert, 'created_at', 'N/A')
        level = getattr(alert, 'level', 'unknown')  # Changed from 'severity' to 'level'
        message = getattr(alert, 'message', 'No message')
        device_id = getattr(alert, 'device_id', 'N/A')
        sensor_id = getattr(alert, 'sensor_id', 'N/A')
        
        prompt += f"\n{i}. [{alert_time}] {str(level).upper()} - Device: {device_id}, Sensor: {sensor_id}\n   Message: {message}\n"
    
    if len(alerts) > 50:
        prompt += f"\n... and {len(alerts) - 50} more alerts\n"
    
    prompt += """

Please generate a professional daily report with the following sections:

1. **Executive Summary**: A brief overview of the day's monitoring activities and key findings (2-3 sentences).

2. **Alert Analysis**: Analyze the patterns in the alerts. What were the most common issues? Are there any concerning trends?

3. **Critical Issues**: Highlight any CRITICAL or WARNING level alerts that require immediate attention.

4. **Device Performance**: Comment on device and sensor performance based on the alert distribution.

5. **Recommendations**: Provide 3-5 actionable recommendations for maintenance or operational improvements.

6. **Conclusion**: A brief conclusion summarizing the overall system health.

IMPORTANT CONTEXT:
- Alert levels are: INFO, WARNING, and CRITICAL
- INFO alerts are informational and low priority
- WARNING alerts indicate potential issues that should be monitored
- CRITICAL alerts require immediate attention

IMPORTANT FORMATTING RULES:
- Use simple paragraph text without special markdown syntax
- For section headers, use the format "SECTION NAME:" on its own line
- Use plain bullet points (•) for lists
- Do NOT use asterisks (*) for bold or italic
- Do NOT use backticks (`) for code
- Keep formatting simple and clean
- Avoid nested formatting or complex HTML-like structures

Format the report in a professional, clear, and actionable manner.
"""
    
    return prompt

def generate_report_with_gemini(prompt):
    """
    Use Gemini API to generate the report text.
    """
    try:
        model = genai.GenerativeModel('gemini-2.5-flash')
        response = model.generate_content(prompt)
        return response.text
    except Exception as e:
        print(f"Error generating report with Gemini: {e}")
        return f"Error generating report: {str(e)}"


def sanitize_html_for_reportlab(text):
    """
    Sanitize HTML text to prevent ReportLab parsing errors.
    Fixes malformed tags and escapes problematic characters.
    """
    import re
    
    # Remove or fix common problematic patterns
    # Fix unclosed bold tags like <b>Text:<b> -> <b>Text:</b>
    text = re.sub(r'<b>([^<]*?)<b>', r'<b>\1</b>', text)
    
    # Fix any remaining malformed tags
    text = re.sub(r'<b>([^<]*?)$', r'<b>\1</b>', text)
    
    # Remove markdown code blocks with backticks
    text = re.sub(r'`([^`]+)`', r'\1', text)
    
    # Remove markdown bold/italic
    text = re.sub(r'\*\*([^\*]+)\*\*', r'<b>\1</b>', text)
    text = re.sub(r'\*([^\*]+)\*', r'\1', text)
    
    # Replace bullet points
    text = text.replace('•', '&#8226;')
    
    # Escape special XML characters that aren't tags
    # But preserve our valid tags
    text = text.replace('&', '&amp;')
    text = text.replace('<', '&lt;')
    text = text.replace('>', '&gt;')
    
    # Restore valid tags
    text = text.replace('&lt;b&gt;', '<b>')
    text = text.replace('&lt;/b&gt;', '</b>')
    text = text.replace('&lt;i&gt;', '<i>')
    text = text.replace('&lt;/i&gt;', '</i>')
    text = text.replace('&lt;br/&gt;', '<br/>')
    text = text.replace('&#8226;', '•')
    
    return text


def is_section_header(text):
    """
    Detect if text is a section header.
    """
    text = text.strip().upper()
    headers = [
        'EXECUTIVE SUMMARY',
        'ALERT ANALYSIS',
        'CRITICAL ISSUES',
        'DEVICE PERFORMANCE',
        'RECOMMENDATIONS',
        'CONCLUSION',
        'DAILY MONITORING REPORT'
    ]
    
    # Check if text starts with a number followed by a period or is in headers list
    if any(text.startswith(h) for h in headers):
        return True
    
    # Check for numbered sections like "1. EXECUTIVE SUMMARY"
    if text and text[0].isdigit() and '.' in text[:3]:
        return True
    
    return False


def create_pdf_report(report_text, alerts, stats, target_date, output_path):
    """
    Create a PDF report using ReportLab.
    """
    doc = SimpleDocTemplate(output_path, pagesize=A4,
                           leftMargin=0.75*inch,
                           rightMargin=0.75*inch,
                           topMargin=0.75*inch,
                           bottomMargin=0.75*inch)
    story = []
    styles = getSampleStyleSheet()
    
    # Custom styles
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Title'],
        fontSize=24,
        textColor=colors.HexColor('#2563eb'),
        spaceAfter=30,
        alignment=TA_CENTER,
        fontName='Helvetica-Bold'
    )
    
    heading_style = ParagraphStyle(
        'CustomHeading',
        parent=styles['Heading1'],
        fontSize=14,
        textColor=colors.HexColor('#2563eb'),
        spaceAfter=8,
        spaceBefore=16,
        fontName='Helvetica-Bold',
        leftIndent=0
    )
    
    subheading_style = ParagraphStyle(
        'CustomSubheading',
        parent=styles['Heading2'],
        fontSize=12,
        textColor=colors.HexColor('#0f172a'),
        spaceAfter=6,
        spaceBefore=12,
        fontName='Helvetica-Bold',
        leftIndent=0
    )
    
    body_style = ParagraphStyle(
        'CustomBody',
        parent=styles['BodyText'],
        fontSize=10,
        alignment=TA_JUSTIFY,
        spaceAfter=10,
        leading=14,
        leftIndent=0,
        fontName='Helvetica'
    )
    
    bullet_style = ParagraphStyle(
        'BulletStyle',
        parent=styles['BodyText'],
        fontSize=10,
        spaceAfter=8,
        leading=14,
        leftIndent=20,
        bulletIndent=10,
        fontName='Helvetica'
    )
    
    # Title
    date_str = target_date.strftime("%B %d, %Y")
    title = Paragraph(f"Daily PLC Monitoring Report", title_style)
    story.append(title)
    
    date_para = Paragraph(date_str, ParagraphStyle(
        'DateStyle',
        parent=styles['Normal'],
        fontSize=14,
        textColor=colors.HexColor('#6b7280'),
        alignment=TA_CENTER,
        spaceAfter=20
    ))
    story.append(date_para)
    story.append(Spacer(1, 0.2*inch))
    
    # Statistics Summary Table
    story.append(Paragraph("Alert Statistics Overview", heading_style))
    
    stats_data = [
        ['Metric', 'Value'],
        ['Total Alerts', str(stats['total'])],
        ['Critical Alerts', str(stats['by_severity'].get('critical', 0))],
        ['Warning Alerts', str(stats['by_severity'].get('warning', 0))],
        ['Info Alerts', str(stats['by_severity'].get('info', 0))],
        ['Unknown Level', str(stats['by_severity'].get('unknown', 0))],
    ]
    
    stats_table = Table(stats_data, colWidths=[3.5*inch, 2*inch])
    stats_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#2563eb')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 11),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
        ('TOPPADDING', (0, 0), (-1, 0), 12),
        ('BACKGROUND', (0, 1), (-1, -1), colors.white),
        ('GRID', (0, 0), (-1, -1), 1, colors.HexColor('#e5e7eb')),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f9fafb')]),
        ('FONTSIZE', (0, 1), (-1, -1), 10),
        ('TOPPADDING', (0, 1), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 1), (-1, -1), 8),
    ]))
    
    story.append(stats_table)
    story.append(Spacer(1, 0.3*inch))
    
    # AI-Generated Report
    story.append(Paragraph("Detailed Analysis", heading_style))
    story.append(Spacer(1, 0.1*inch))
    
    # Split report text by lines and process
    lines = report_text.split('\n')
    current_paragraph = []
    
    for line in lines:
        line = line.strip()
        
        # Skip empty lines
        if not line:
            # Process accumulated paragraph
            if current_paragraph:
                para_text = ' '.join(current_paragraph)
                clean_text = sanitize_html_for_reportlab(para_text)
                
                try:
                    story.append(Paragraph(clean_text, body_style))
                except Exception as e:
                    print(f"Warning: Could not parse paragraph: {str(e)[:100]}")
                
                current_paragraph = []
            continue
        
        # Check if it's a section header
        if is_section_header(line):
            # Process any accumulated paragraph first
            if current_paragraph:
                para_text = ' '.join(current_paragraph)
                clean_text = sanitize_html_for_reportlab(para_text)
                try:
                    story.append(Paragraph(clean_text, body_style))
                except:
                    pass
                current_paragraph = []
            
            # Add the header
            # Remove numbering if present
            header_text = line
            if header_text and header_text[0].isdigit():
                header_text = header_text.split('.', 1)[-1].strip()
            
            # Remove colons
            header_text = header_text.rstrip(':')
            
            try:
                story.append(Paragraph(header_text.title(), subheading_style))
            except:
                pass
            continue
        
        # Check if it's a bullet point
        if line.startswith('•') or line.startswith('-') or line.startswith('*'):
            # Process any accumulated paragraph first
            if current_paragraph:
                para_text = ' '.join(current_paragraph)
                clean_text = sanitize_html_for_reportlab(para_text)
                try:
                    story.append(Paragraph(clean_text, body_style))
                except:
                    pass
                current_paragraph = []
            
            # Add bullet point
            bullet_text = line.lstrip('•-*').strip()
            clean_text = sanitize_html_for_reportlab(bullet_text)
            try:
                story.append(Paragraph(f"• {clean_text}", bullet_style))
            except:
                pass
            continue
        
        # Regular text - accumulate
        current_paragraph.append(line)
    
    # Process last paragraph
    if current_paragraph:
        para_text = ' '.join(current_paragraph)
        clean_text = sanitize_html_for_reportlab(para_text)
        try:
            story.append(Paragraph(clean_text, body_style))
        except:
            pass
    
    story.append(Spacer(1, 0.3*inch))
    
    # Add a separator line
    from reportlab.platypus import HRFlowable
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#e5e7eb'), 
                            spaceAfter=0.2*inch, spaceBefore=0.1*inch))
    
    # Footer
    footer_style = ParagraphStyle(
        'Footer',
        parent=styles['Normal'],
        fontSize=9,
        textColor=colors.HexColor('#6b7280'),
        alignment=TA_CENTER
    )
    
    generation_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    footer = Paragraph(f"Report generated on {generation_time} | PLC Monitoring System", footer_style)
    story.append(footer)
    
    # Build PDF
    doc.build(story)
    print(f"PDF report created: {output_path}")


def daily_report():
    """
    Main function to generate daily report.
    """
    cairo_tz = timezone("Africa/Cairo")
    
    # Get yesterday's date (report runs at 4 AM for previous day)
    now = datetime.now(cairo_tz)
    target_date = (now - timedelta(days=0)).date()
    
    print(f"\n{'='*60}")
    print(f"Starting daily report generation for {target_date}")
    print(f"{'='*60}\n")
    
    
    try:
        # 1. Fetch alerts from database
        print("Fetching alerts from database...")
        alerts = fetch_daily_alerts(db, target_date)
        print(f"Found {len(alerts)} alerts")
        
        if len(alerts) == 0:
            print("No alerts found for this day. Skipping report generation.")
            return True
        
        # 2. Calculate statistics
        print("Calculating statistics...")
        stats = get_alert_statistics(alerts)
        
        # 3. Generate prompt for Gemini
        print("Preparing data for AI analysis...")
        prompt = format_alerts_for_gemini(alerts, stats, target_date)
        
        # 4. Generate report text with Gemini
        print("Generating report with Gemini AI...")
        report_text = generate_report_with_gemini(prompt)
        print("Report text generated successfully")
        
        # 5. Create PDF
        date_str = target_date.strftime("%Y-%m-%d")
        output_filename = f"daily_report_{date_str}.pdf"
        output_path = os.path.join(REPORTS_DIR, output_filename)
        
        print(f"Creating PDF report: {output_filename}")
        create_pdf_report(report_text, alerts, stats, target_date, output_path)
        report_to_add = models.Report(
            report_type = 'Daily',
            file_path=output_path
        )
        db.add(report_to_add)
        db.commit()
        
        print(f"\n{'='*60}")
        print(f"Daily report generated successfully!")
        print(f"Location: {output_path}")
        print(f"{'='*60}\n")
        
        return True
        
    except Exception as e:
        print(f"Error generating daily report: {e}")
        import traceback
        traceback.print_exc()
        return False
        
    finally:
        db.close()


daily_report()

# if __name__ == "__main__":
#     # You can run manually for testing
#     # daily_report()
    
#     # Or run on schedule
#     cairo_tz = timezone("Africa/Cairo")
#     schedule.every().day.at("04:00", "Africa/Cairo").do(daily_report)
    
#     print("Daily report scheduler started. Reports will be generated at 04:00 Cairo time.")
#     print(f"Reports will be saved to: {REPORTS_DIR}")
#     print("Press Ctrl+C to stop.")
    
#     while True:
#         schedule.run_pending()
#         time.sleep(1)
