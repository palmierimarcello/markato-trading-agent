from flask import Flask, jsonify, request
from flask_cors import CORS
from datetime import datetime, timezone
import db_utils
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
CORS(app)

# Inizializza il database all'avvio
try:
    db_utils.init_db()
    print("[API] Database initialized successfully")
except Exception as e:
    print(f"[API] Error initializing database: {e}")


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint per verificare che l'API sia attiva"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "service": "Trading Agent API"
    }), 200


@app.route('/status', methods=['GET'])
def get_status():
    """Restituisce lo stato attuale dell'account e posizioni aperte"""
    try:
        snapshot = db_utils.get_latest_account_snapshot()
        if not snapshot:
            return jsonify({
                "status": "no_data",
                "message": "No account snapshots found"
            }), 404

        return jsonify({
            "status": "success",
            "data": snapshot,
            "timestamp": datetime.now(timezone.utc).isoformat()
        }), 200

    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500


@app.route('/operations', methods=['GET'])
def get_operations():
    """Restituisce le ultime operazioni del bot"""
    try:
        limit = request.args.get('limit', default=50, type=int)
        operations = db_utils.get_recent_bot_operations(limit=limit)

        return jsonify({
            "status": "success",
            "count": len(operations),
            "data": operations,
            "timestamp": datetime.now(timezone.utc).isoformat()
        }), 200

    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500


@app.route('/performance', methods=['GET'])
def get_performance():
    """Calcola e restituisce metriche di performance"""
    try:
        with db_utils.get_connection() as conn:
            with conn.cursor() as cur:
                # Recupera tutti gli snapshots ordinati per data
                cur.execute("""
                    SELECT created_at, balance_usd
                    FROM account_snapshots
                    ORDER BY created_at ASC
                """)
                snapshots = cur.fetchall()

                if len(snapshots) < 2:
                    return jsonify({
                        "status": "insufficient_data",
                        "message": "Need at least 2 snapshots to calculate performance"
                    }), 200

                initial_balance = float(snapshots[0][1])
                current_balance = float(snapshots[-1][1])
                total_return = ((current_balance - initial_balance) / initial_balance) * 100

                # Conta operazioni per tipo
                cur.execute("""
                    SELECT operation, COUNT(*)
                    FROM bot_operations
                    GROUP BY operation
                """)
                operations_by_type = dict(cur.fetchall())

                return jsonify({
                    "status": "success",
                    "data": {
                        "initial_balance": round(initial_balance, 2),
                        "current_balance": round(current_balance, 2),
                        "total_return_percent": round(total_return, 2),
                        "total_snapshots": len(snapshots),
                        "operations_by_type": operations_by_type,
                        "first_snapshot": snapshots[0][0].isoformat(),
                        "last_snapshot": snapshots[-1][0].isoformat()
                    },
                    "timestamp": datetime.now(timezone.utc).isoformat()
                }), 200

    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500


@app.route('/', methods=['GET'])
def index():
    """Root endpoint con info sull'API"""
    return jsonify({
        "service": "Trading Agent API",
        "version": "1.0.0",
        "endpoints": {
            "/health": "Health check",
            "/status": "Current account status",
            "/operations": "Recent bot operations (param: limit)",
            "/performance": "Performance metrics"
        },
        "timestamp": datetime.now(timezone.utc).isoformat()
    }), 200


if __name__ == '__main__':
    port = int(os.getenv('API_PORT', 8000))
    app.run(host='0.0.0.0', port=port, debug=False)
